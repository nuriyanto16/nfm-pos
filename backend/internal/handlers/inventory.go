package handlers

import (
	"net/http"
	"time"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"strconv"
	"fmt"
)

// ─── Goods Receipt (Barang Masuk) ─────────────────────────────────────────────

func GetGoodsReceipts(c *gin.Context) {
	var receipts []models.GoodsReceipt
	db := database.DB.Model(&models.GoodsReceipt{}).Scopes(middleware.GetQueryScope(c)).Preload("Branch").Preload("Supplier")

	pagination, err := Paginate(c, db.Order("created_at DESC"), &receipts)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch goods receipts"})
		return
	}
	c.JSON(http.StatusOK, pagination)
}

func CreateGoodsReceipt(c *gin.Context) {
	var receipt models.GoodsReceipt
	if err := c.ShouldBindJSON(&receipt); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	companyID, _ := c.Get("companyID")
	receipt.CompanyID = companyID.(uint)
	branchID, _ := c.Get("branchID")
	if receipt.BranchID == 0 && branchID != nil {
		receipt.BranchID = branchID.(uint)
	}

	receipt.ReceiptNo = "GR-" + uuid.New().String()[:8]
	if receipt.ReceiptDate.IsZero() {
		receipt.ReceiptDate = time.Now()
	}
	// Initial status is Draft
	receipt.Status = "Draft"

	tx := database.DB.Begin()
	// Clear item IDs to avoid primary key collision
	for i := range receipt.Items {
		receipt.Items[i].ID = 0
	}

	if err := tx.Create(&receipt).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create goods receipt: " + err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusCreated, receipt)
}

func ApproveGoodsReceipt(c *gin.Context) {
	id := c.Param("id")
	var receipt models.GoodsReceipt
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Preload("Items").First(&receipt, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Receipt not found"})
		return
	}

	if receipt.Status != "Draft" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Only Draft receipts can be approved"})
		return
	}

	tx := database.DB.Begin()

	// Update Status
	if err := tx.Model(&receipt).Update("status", "Approved").Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to approve receipt"})
		return
	}

	for _, item := range receipt.Items {
		// Update Ingredient Stock
		if err := tx.Model(&models.Ingredient{}).Where("id = ?", item.IngredientID).UpdateColumn("stock", database.DB.Raw("stock + ?", item.Quantity)).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ingredient stock"})
			return
		}

		// Add Stock History
		history := models.StockHistory{
			CompanyID:    receipt.CompanyID,
			BranchID:     receipt.BranchID,
			IngredientID: item.IngredientID,
			Type:         "IN",
			Quantity:     item.Quantity,
			UserID:       c.GetUint("userID"),
			Notes:        "Approved Goods Receipt: " + receipt.ReceiptNo,
		}
		if err := tx.Create(&history).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create stock history"})
			return
		}
	}

	// If linked to a Branch Order, update its status
	if receipt.BranchOrderID != nil && *receipt.BranchOrderID != 0 {
		if err := tx.Model(&models.BranchOrder{}).Where("id = ?", *receipt.BranchOrderID).Update("status", "Fulfilled").Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update branch order status"})
			return
		}
	}

	tx.Commit()

	// ─── Automatic Journal Posting ──────────────────────────────────────────
	go PostJournalEntryForGoodsReceipt(receipt)

	c.JSON(http.StatusOK, gin.H{"message": "Receipt approved successfully"})
}

// ─── Goods Issue (Barang Keluar) ──────────────────────────────────────────────

func GetGoodsIssues(c *gin.Context) {
	var issues []models.GoodsIssue
	db := database.DB.Model(&models.GoodsIssue{}).Scopes(middleware.GetQueryScope(c)).Preload("Branch")

	pagination, err := Paginate(c, db.Order("created_at DESC"), &issues)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch goods issues"})
		return
	}
	c.JSON(http.StatusOK, pagination)
}

func CreateGoodsIssue(c *gin.Context) {
	var issue models.GoodsIssue
	if err := c.ShouldBindJSON(&issue); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	companyID, _ := c.Get("companyID")
	issue.CompanyID = companyID.(uint)
	issue.IssueNo = "GI-" + uuid.New().String()[:8]
	if issue.IssueDate.IsZero() {
		issue.IssueDate = time.Now()
	}
	issue.Status = "Draft"

	tx := database.DB.Begin()
	for i := range issue.Items {
		issue.Items[i].ID = 0
	}

	if err := tx.Create(&issue).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create goods issue: " + err.Error()})
		return
	}

	tx.Commit()
	c.JSON(http.StatusCreated, issue)
}

func ApproveGoodsIssue(c *gin.Context) {
	id := c.Param("id")
	var issue models.GoodsIssue
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Preload("Items").First(&issue, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Issue not found"})
		return
	}

	if issue.Status != "Draft" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Only Draft issues can be approved"})
		return
	}

	tx := database.DB.Begin()

	// Update Status
	if err := tx.Model(&issue).Update("status", "Approved").Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to approve issue"})
		return
	}

	for _, item := range issue.Items {
		// Update Ingredient Stock
		if err := tx.Model(&models.Ingredient{}).Where("id = ?", item.IngredientID).UpdateColumn("stock", database.DB.Raw("stock - ?", item.Quantity)).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ingredient stock"})
			return
		}

		// Add Stock History
		history := models.StockHistory{
			CompanyID:    issue.CompanyID,
			BranchID:     issue.BranchID,
			IngredientID: item.IngredientID,
			Type:         "OUT",
			Quantity:     item.Quantity,
			UserID:       c.GetUint("userID"),
			Notes:        "Approved Goods Issue: " + issue.IssueNo + " - " + item.Notes,
		}
		if err := tx.Create(&history).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create stock history"})
			return
		}
	}

	tx.Commit()

	// ─── Automatic Journal Posting ──────────────────────────────────────────
	go PostJournalEntryForGoodsIssue(issue)

	c.JSON(http.StatusOK, gin.H{"message": "Issue approved successfully"})
}

func GetGoodsReceiptByID(c *gin.Context) {
	id := c.Param("id")
	var receipt models.GoodsReceipt
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Preload("Items.Ingredient").Preload("Branch").Preload("Supplier").First(&receipt, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Receipt not found"})
		return
	}
	c.JSON(http.StatusOK, receipt)
}

func GetGoodsIssueByID(c *gin.Context) {
	id := c.Param("id")
	var issue models.GoodsIssue
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Preload("Items.Ingredient").Preload("Branch").First(&issue, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Issue not found"})
		return
	}
	c.JSON(http.StatusOK, issue)
}

// ─── Finance Integration ──────────────────────────────────────────────────

func PostJournalEntryForGoodsReceipt(receipt models.GoodsReceipt) {
	var inventoryAccount models.Account
	var apAccount models.Account

	// Find accounts
	var settings []models.SystemSetting
	database.DB.Where("branch_id = ? OR branch_id IS NULL", receipt.BranchID).Find(&settings)
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
		database.DB.Where("(branch_id = ? OR branch_id IS NULL) AND code = ?", receipt.BranchID, defaultCode).Order("branch_id DESC").First(target)
	}

	getAccount("acc_inventory_id", "1201", &inventoryAccount)
	getAccount("acc_ap_id", "2102", &apAccount)

	if inventoryAccount.ID == 0 || apAccount.ID == 0 {
		fmt.Printf("⚠️  Skipping journal posting for GR #%s: Mandatory account missing\n", receipt.ReceiptNo)
		return
	}

	entry := models.JournalEntry{
		CompanyID:   receipt.CompanyID,
		BranchID:    receipt.BranchID,
		Date:        time.Now(),
		Description: "Penerimaan Barang #" + receipt.ReceiptNo,
		Reference:   receipt.ReceiptNo,
		TotalAmount: receipt.TotalAmount,
	}

	tx := database.DB.Begin()
	if err := tx.Create(&entry).Error; err != nil {
		tx.Rollback()
		return
	}

	// Debit Inventory
	tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: inventoryAccount.ID, Debit: receipt.TotalAmount})
	// Credit Accounts Payable
	tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: apAccount.ID, Credit: receipt.TotalAmount})

	tx.Commit()
	fmt.Printf("✅ Journal posted for GR #%s\n", receipt.ReceiptNo)
}

func PostJournalEntryForGoodsIssue(issue models.GoodsIssue) {
	var inventoryAccount models.Account
	var expenseAccount models.Account

	// Find accounts
	var settings []models.SystemSetting
	database.DB.Where("branch_id = ? OR branch_id IS NULL", issue.BranchID).Find(&settings)
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
		database.DB.Where("(branch_id = ? OR branch_id IS NULL) AND code = ?", issue.BranchID, defaultCode).Order("branch_id DESC").First(target)
	}

	getAccount("acc_inventory_id", "1201", &inventoryAccount)
	getAccount("acc_expense_id", "5102", &expenseAccount)

	if inventoryAccount.ID == 0 || expenseAccount.ID == 0 {
		fmt.Printf("⚠️  Skipping journal posting for GI #%s: Mandatory account missing\n", issue.IssueNo)
		return
	}

	// Calculate Total Value of Issue efficiently
	var totalValue float64
	var ingredientIDs []uint
	qtyMap := make(map[uint]float64)
	for _, item := range issue.Items {
		ingredientIDs = append(ingredientIDs, item.IngredientID)
		qtyMap[item.IngredientID] += item.Quantity
	}

	var ingredients []models.Ingredient
	database.DB.Where("id IN ?", ingredientIDs).Find(&ingredients)
	for _, ing := range ingredients {
		totalValue += qtyMap[ing.ID] * ing.CostPerUnit
	}

	if totalValue <= 0 {
		return
	}

	entry := models.JournalEntry{
		CompanyID:   issue.CompanyID,
		BranchID:    issue.BranchID,
		Date:        time.Now(),
		Description: "Pengeluaran Barang #" + issue.IssueNo + " (" + issue.IssueCategory + ")",
		Reference:   issue.IssueNo,
		TotalAmount: totalValue,
	}

	tx := database.DB.Begin()
	if err := tx.Create(&entry).Error; err != nil {
		tx.Rollback()
		return
	}

	// Debit Expense
	tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: expenseAccount.ID, Debit: totalValue})
	// Credit Inventory
	tx.Create(&models.JournalItem{JournalID: entry.ID, AccountID: inventoryAccount.ID, Credit: totalValue})

	tx.Commit()
	fmt.Printf("✅ Journal posted for GI #%s\n", issue.IssueNo)
}
