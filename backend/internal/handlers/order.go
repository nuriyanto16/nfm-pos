package handlers

import (
	"fmt"
	"net/http"
	"strings"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"
	"pos-resto/backend/internal/services"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type CreateOrderRequest struct {
	TableID        *uint              `json:"table_id"`
	CustomerID     *uint              `json:"customer_id"`
	CustomerName   string             `json:"customer_name"`
	Notes          string             `json:"notes"`
	DiscountAmount float64            `json:"discount_amount"`
	ShippingFee    float64            `json:"shipping_fee"`
	Items          []models.OrderItem `json:"items" binding:"required"`
}

func GetOrders(c *gin.Context) {
	var orders []models.Order
	db := database.DB.Model(&models.Order{}).Scopes(middleware.GetQueryScope(c)).Preload("Table").Preload("User").Preload("Items.Menu").Preload("Customer")

	// Optional filters
	status := c.Query("status")
	if status != "" {
		statusList := strings.Split(status, ",")
		if len(statusList) > 1 {
			db = db.Where("status IN ?", statusList)
		} else {
			db = db.Where("status = ?", status)
		}
	}

	pagination, err := Paginate(c, db.Order("created_at desc"), &orders)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch orders"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func GetOrderByID(c *gin.Context) {
	id := c.Param("id")
	var order models.Order
	if err := database.DB.Preload("Table").Preload("User").Preload("Items.Menu").Preload("Customer").Preload("Promo").First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}
	c.JSON(http.StatusOK, order)
}

func CreateOrder(c *gin.Context) {
	var req CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userId, _ := c.Get("userID")

	// Calculate totals
	var total float64
	for i, item := range req.Items {
		var menu models.Menu
		if err := database.DB.First(&menu, item.MenuID).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Menu not found"})
			return
		}
		itemSubtotal := menu.Price * float64(item.Quantity)
		req.Items[i].Price = menu.Price
		req.Items[i].Subtotal = itemSubtotal
		total += itemSubtotal
	}

	// Get branch from context (set by AuthMiddleware)
	val, exists := c.Get("branchID")
	var finalBranchID uint
	if !exists {
		// Fallback for global admin: use the first branch
		var firstBranch models.Branch
		if err := database.DB.First(&firstBranch).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "No branch found in system"})
			return
		}
		finalBranchID = firstBranch.ID
	} else {
		finalBranchID = val.(uint)
	}

	userId, ok := c.Get("userID")
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found"})
		return
	}
	finalUserID := userId.(uint)

	// Get dynamic settings
	var settings []models.SystemSetting
	database.DB.Where("branch_id = ? OR branch_id IS NULL", finalBranchID).Find(&settings)
	settingsMap := make(map[string]string)
	for _, s := range settings {
		settingsMap[s.Key] = s.Value
	}

	taxPct := 0.1 // Default 10%
	if val, ok := settingsMap["tax_pct"]; ok {
		taxPct, _ = strconv.ParseFloat(val, 64)
		taxPct = taxPct / 100
	}

	servicePct := 0.0 // Default 0%
	if val, ok := settingsMap["service_charge_pct"]; ok {
		servicePct, _ = strconv.ParseFloat(val, 64)
		servicePct = servicePct / 100
	}

	serviceCharge := total * servicePct
	tax := (total + serviceCharge) * taxPct

	order := models.Order{
		BranchID:            finalBranchID,
		TableID:             req.TableID,
		CustomerID:          req.CustomerID,
		UserID:              finalUserID,
		CustomerName:        req.CustomerName,
		Status:              "Pending",
		TotalAmount:         total + tax + serviceCharge + req.ShippingFee - req.DiscountAmount,
		TaxAmount:           tax,
		ServiceChargeAmount: serviceCharge,
		DiscountAmount:      req.DiscountAmount,
		ShippingFee:         req.ShippingFee,
		Notes:               req.Notes,
		Items:               req.Items,
	}

	// Update table status if TableID is provided
	tx := database.DB.Begin()

	if err := tx.Create(&order).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create order"})
		return
	}

	if req.TableID != nil {
		if err := tx.Model(&models.Table{}).Where("id = ?", req.TableID).Update("status", "Digunakan").Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update table status"})
			return
		}
	}

	// Deduct ingredients
	for _, item := range order.Items {
		var recipe []models.MenuIngredient
		if err := tx.Where("menu_id = ?", item.MenuID).Find(&recipe).Error; err == nil {
			for _, ingredient := range recipe {
				qtyToDeduct := ingredient.QtyUsed * float64(item.Quantity)
				if err := tx.Model(&models.Ingredient{}).Where("id = ?", ingredient.IngredientID).
					Update("stock", gorm.Expr("stock - ?", qtyToDeduct)).Error; err != nil {
					tx.Rollback()
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ingredient stock"})
					return
				}

				// Log Stock History
				tx.Create(&models.StockHistory{
					BranchID:     order.BranchID,
					IngredientID: ingredient.IngredientID,
					OrderID:      &order.ID,
					Type:         "OUT",
					Quantity:     qtyToDeduct,
					Notes:        "Order #" + strconv.FormatUint(uint64(order.ID), 10),
				})
			}
		}
	}

	tx.Commit()
	c.JSON(http.StatusCreated, order)
}

func UpdateOrderStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status string `json:"status"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order models.Order
	if err := database.DB.First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	// Update order status
	if err := database.DB.Model(&order).Update("status", req.Status).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update order status"})
		return
	}
	
	// If order is completed or cancelled, free the table
	if (req.Status == "Selesai" || req.Status == "Batal") && order.TableID != nil {
		database.DB.Model(&models.Table{}).Where("id = ?", order.TableID).Update("status", "Kosong")
	}

	c.JSON(http.StatusOK, gin.H{"message": "Status updated successfully"})
}

func ProcessPayment(c *gin.Context) {
	orderID := c.Param("id")
	var payment models.Payment
	if err := c.ShouldBindJSON(&payment); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order models.Order
	if err := database.DB.Preload("Items").First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	payment.OrderID = order.ID
	payment.BranchID = order.BranchID // Ensure payment is linked to the same branch as the order

	tx := database.DB.Begin()
	if err := tx.Create(&payment).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Payment failed"})
		return
	}

	// Update order status and paid flag
	updateData := map[string]interface{}{"is_paid": true, "status": "Selesai"}
	if err := tx.Model(&order).Updates(updateData).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update order status"})
		return
	}
	
	if order.TableID != nil {
		if err := tx.Model(&models.Table{}).Where("id = ?", order.TableID).Update("status", "Kosong").Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to release table"})
			return
		}
	}

	// Update Customer total spent and tier
	if order.CustomerID != nil {
		var customer models.Customer
		if err := tx.First(&customer, order.CustomerID).Error; err == nil {
			newTotal := customer.TotalSpent + order.TotalAmount
			newTier := "Bronze"
			if newTotal > 5000000 {
				newTier = "Gold"
			} else if newTotal > 1000000 {
				newTier = "Silver"
			}
			
			tx.Model(&customer).Updates(map[string]interface{}{
				"total_spent": newTotal,
				"tier":        newTier,
			})
		}
	}

	tx.Commit()

	// ─── Additional Automation (Background) ──────────────────────────────────
	if order.CustomerID != nil {
		var customer models.Customer
		if err := database.DB.First(&customer, order.CustomerID).Error; err == nil {
			go services.SendReceiptToWA(customer, order)
		}
	}

	// ─── Automatic Journal Posting ──────────────────────────────────────────
	go PostJournalEntryForPayment(order, payment)

	c.JSON(http.StatusOK, payment)
}

func VoidOrder(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Reason string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order models.Order
	if err := database.DB.Preload("Items").First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	if order.Status == "Batal" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Order is already voided"})
		return
	}

	tx := database.DB.Begin()

	// Update Status
	if err := tx.Model(&order).Updates(map[string]interface{}{
		"status":      "Batal",
		"void_reason": req.Reason,
	}).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to void order"})
		return
	}

	// Revert Ingredients Stock
	for _, item := range order.Items {
		var recipe []models.MenuIngredient
		if err := tx.Where("menu_id = ?", item.MenuID).Find(&recipe).Error; err == nil {
			for _, ingredient := range recipe {
				qtyToRestore := ingredient.QtyUsed * float64(item.Quantity)
				tx.Model(&models.Ingredient{}).Where("id = ?", ingredient.IngredientID).
					Update("stock", gorm.Expr("stock + ?", qtyToRestore))

				// Log Stock History
				tx.Create(&models.StockHistory{
					BranchID:     order.BranchID,
					IngredientID: ingredient.IngredientID,
					OrderID:      &order.ID,
					Type:         "VOID",
					Quantity:     qtyToRestore,
					Notes:        "Void Order #" + strconv.FormatUint(uint64(order.ID), 10),
				})
			}
		}
	}

	// Release Table
	if order.TableID != nil {
		tx.Model(&models.Table{}).Where("id = ?", order.TableID).Update("status", "Kosong")
	}

	tx.Commit()

	// Revert Journal Entry if payment exists
	go PostJournalEntryForVoid(order)

	c.JSON(http.StatusOK, gin.H{"message": "Order voided successfully"})
}

// ─── Finance Integration ──────────────────────────────────────────────────

func PostJournalEntryForPayment(order models.Order, payment models.Payment) {
	var bankAccount models.Account
	var salesAccount models.Account
	var taxAccount models.Account
	var serviceAccount models.Account
	var hppAccount models.Account
	var inventoryAccount models.Account

	// Find accounts using dynamic settings or defaults
	var settings []models.SystemSetting
	database.DB.Where("branch_id = ? OR branch_id IS NULL", order.BranchID).Find(&settings)
	settingsMap := make(map[string]string)
	for _, s := range settings {
		settingsMap[s.Key] = s.Value
	}

	getAccount := func(settingKey, defaultCode string, target *models.Account) {
		if idStr, ok := settingsMap[settingKey]; ok {
			if id, err := strconv.ParseUint(idStr, 10, 64); err == nil {
				database.DB.First(target, uint(id))
				if target.ID != 0 {
					return
				}
			}
		}
		// Fallback to code (branch-specific or global)
		database.DB.Where("(branch_id = ? OR branch_id IS NULL) AND code = ?", order.BranchID, defaultCode).Order("branch_id DESC").First(target)
	}

	getAccount("acc_cash_id", "1101", &bankAccount)
	getAccount("acc_sales_id", "4101", &salesAccount)
	getAccount("acc_tax_id", "2101", &taxAccount)
	getAccount("acc_service_id", "4102", &serviceAccount)
	getAccount("acc_hpp_id", "5101", &hppAccount)
	getAccount("acc_inventory_id", "1201", &inventoryAccount)

	entry := models.JournalEntry{
		BranchID:    order.BranchID,
		Date:        time.Now(),
		Description: "Penjualan Order #" + strconv.FormatUint(uint64(order.ID), 10),
		Reference:   "ORDER-" + strconv.FormatUint(uint64(order.ID), 10),
		TotalAmount: order.TotalAmount,
	}

	tx := database.DB.Begin()
	if err := tx.Create(&entry).Error; err != nil {
		tx.Rollback()
		return
	}

	// Items (Net Sales)
	subtotalItems := order.TotalAmount - order.TaxAmount - order.ServiceChargeAmount - order.ShippingFee + order.DiscountAmount

	// Validation: ensure mandatory accounts exist
	if bankAccount.ID == 0 || salesAccount.ID == 0 {
		tx.Rollback()
		fmt.Printf("⚠️  Skipping journal posting for Order #%d: Mandatory account missing (Cash/Sales)\n", order.ID)
		return
	}

	// Debit Cash
	tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: bankAccount.ID, Debit: order.TotalAmount})
	// Credit Sales
	tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: salesAccount.ID, Credit: subtotalItems})
	// Credit Tax
	if order.TaxAmount > 0 && taxAccount.ID != 0 {
		tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: taxAccount.ID, Credit: order.TaxAmount})
	}
	// Credit Service
	if order.ServiceChargeAmount > 0 && serviceAccount.ID != 0 {
		tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: serviceAccount.ID, Credit: order.ServiceChargeAmount})
	}

	// --- HPP Posting ---
	var totalHPP float64
	for _, item := range order.Items {
		var recipe []models.MenuIngredient
		if err := database.DB.Preload("Ingredient").Where("menu_id = ?", item.MenuID).Find(&recipe).Error; err == nil {
			for _, ing := range recipe {
				if ing.IngredientID != 0 {
					totalHPP += ing.QtyUsed * float64(item.Quantity) * ing.Ingredient.CostPerUnit
				}
			}
		}
	}

	if totalHPP > 0 && hppAccount.ID != 0 && inventoryAccount.ID != 0 {
		// Debit HPP
		tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: hppAccount.ID, Debit: totalHPP})
		// Credit Inventory
		tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: inventoryAccount.ID, Credit: totalHPP})
	}

	tx.Commit()
	fmt.Printf("✅ Journal posted for Order #%d\n", order.ID)
}

func PostJournalEntryForVoid(order models.Order) {
	var bankAccount models.Account
	var salesAccount models.Account
	var taxAccount models.Account
	var serviceAccount models.Account

	// Find accounts using dynamic settings or defaults
	var settings []models.SystemSetting
	database.DB.Where("branch_id = ? OR branch_id IS NULL", order.BranchID).Find(&settings)
	settingsMap := make(map[string]string)
	for _, s := range settings {
		settingsMap[s.Key] = s.Value
	}

	getAccount := func(settingKey, defaultCode string, target *models.Account) {
		if idStr, ok := settingsMap[settingKey]; ok {
			if id, err := strconv.ParseUint(idStr, 10, 64); err == nil {
				database.DB.First(target, uint(id))
				if target.ID != 0 {
					return
				}
			}
		}
		// Fallback to code (branch-specific or global)
		database.DB.Where("(branch_id = ? OR branch_id IS NULL) AND code = ?", order.BranchID, defaultCode).Order("branch_id DESC").First(target)
	}

	getAccount("acc_cash_id", "1101", &bankAccount)
	getAccount("acc_sales_id", "4101", &salesAccount)
	getAccount("acc_tax_id", "2101", &taxAccount)
	getAccount("acc_service_id", "4102", &serviceAccount)

	entry := models.JournalEntry{
		BranchID:    order.BranchID,
		Date:        time.Now(),
		Description: "Reversal Order #" + strconv.FormatUint(uint64(order.ID), 10) + " (VOID)",
		Reference:   "VOID-" + strconv.FormatUint(uint64(order.ID), 10),
		TotalAmount: order.TotalAmount,
	}

	tx := database.DB.Begin()
	if err := tx.Create(&entry).Error; err != nil {
		tx.Rollback()
		return
	}

	subtotalItems := order.TotalAmount - order.TaxAmount - order.ServiceChargeAmount - order.ShippingFee + order.DiscountAmount

	// Validation
	if bankAccount.ID == 0 || salesAccount.ID == 0 {
		tx.Rollback()
		fmt.Printf("⚠️  Skipping VOID journal posting for Order #%d: Mandatory account missing\n", order.ID)
		return
	}

	// Credit Cash (Reversal)
	tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: bankAccount.ID, Credit: order.TotalAmount})
	// Debit Sales (Reversal)
	tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: salesAccount.ID, Debit: subtotalItems})
	// Debit Tax (Reversal)
	if order.TaxAmount > 0 && taxAccount.ID != 0 {
		tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: taxAccount.ID, Debit: order.TaxAmount})
	}
	// Debit Service (Reversal)
	if order.ServiceChargeAmount > 0 && serviceAccount.ID != 0 {
		tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: serviceAccount.ID, Debit: order.ServiceChargeAmount})
	}

	// --- HPP Reversal Posting ---
	var totalHPP float64
	var hppAccount, inventoryAccount models.Account
	getAccount("acc_hpp_id", "5101", &hppAccount)
	getAccount("acc_inventory_id", "1201", &inventoryAccount)

	for _, item := range order.Items {
		var recipe []models.MenuIngredient
		if err := database.DB.Preload("Ingredient").Where("menu_id = ?", item.MenuID).Find(&recipe).Error; err == nil {
			for _, ing := range recipe {
				if ing.IngredientID != 0 {
					totalHPP += ing.QtyUsed * float64(item.Quantity) * ing.Ingredient.CostPerUnit
				}
			}
		}
	}

	if totalHPP > 0 && hppAccount.ID != 0 && inventoryAccount.ID != 0 {
		// Debit Inventory (Reversal)
		tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: inventoryAccount.ID, Debit: totalHPP})
		// Credit HPP (Reversal)
		tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: hppAccount.ID, Credit: totalHPP})
	}

	tx.Commit()
	fmt.Printf("✅ VOID Journal posted for Order #%d\n", order.ID)
}
