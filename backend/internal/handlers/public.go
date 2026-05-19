package handlers

import (
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// ─── Public Branch List ───────────────────────────────────────────────────────

type PublicBranchResponse struct {
	ID        uint   `json:"id"`
	Name      string `json:"name"`
	Code      string `json:"code"`
	Address   string `json:"address"`
	Phone     string `json:"phone"`
	IsOpen    bool   `json:"is_open"`
	OpenTime  string `json:"open_time"`
	CloseTime string `json:"close_time"`
}

func PublicGetBranches(c *gin.Context) {
	companyCode := c.Param("code")

	// Find company by code OR by ID (if numeric)
	var company models.Company
	err := database.DB.Where("code = ?", companyCode).First(&company).Error
	if err != nil {
		// Try by ID
		err = database.DB.Where("id = ?", companyCode).First(&company).Error
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Company not found"})
			return
		}
	}

	// Get branches
	var branches []models.Branch
	database.DB.Where("company_id = ? AND is_active = true", company.ID).Find(&branches)

	// Build response with open/close status
	var result []PublicBranchResponse
	for _, b := range branches {
		openTime, closeTime, isOpen := getBranchOperatingStatus(b.ID)
		result = append(result, PublicBranchResponse{
			ID:        b.ID,
			Name:      b.Name,
			Code:      b.Code,
			Address:   b.Address,
			Phone:     b.Phone,
			IsOpen:    isOpen,
			OpenTime:  openTime,
			CloseTime: closeTime,
		})
	}

	// Fetch theme settings from system_settings
	var settings []models.SystemSetting
	database.DB.Where("company_id = ? AND branch_id IS NULL", company.ID).Find(&settings)
	
	theme := make(map[string]string)
	for _, s := range settings {
		if s.Key == "primary_color" || s.Key == "secondary_color" || s.Key == "accent_color" {
			theme[s.Key] = s.Value
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"company": gin.H{
			"id":       company.ID,
			"name":     company.Name,
			"code":     company.Code,
			"logo_url": company.LogoURL,
			"address":  company.Address,
			"phone":    company.Phone,
			"email":    company.Email,
			"theme":    theme,
		},
		"branches": result,
	})
}

// ─── Public Menu by Branch ────────────────────────────────────────────────────

type PublicMenuItem struct {
	ID          uint    `json:"id"`
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Price       float64 `json:"price"`
	ImageURL    string  `json:"image_url"`
	IsAvailable bool    `json:"is_available"`
	CategoryID  uint    `json:"category_id"`
}

type PublicCategoryWithMenus struct {
	ID    uint             `json:"id"`
	Name  string           `json:"name"`
	Items []PublicMenuItem `json:"items"`
}

func PublicGetMenuByBranch(c *gin.Context) {
	branchID := c.Param("branchId")

	var branch models.Branch
	if err := database.DB.First(&branch, branchID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Branch not found"})
		return
	}

	// Get categories for this branch/company
	var categories []models.Category
	database.DB.Where("company_id = ? AND (branch_id = ? OR branch_id IS NULL)", branch.CompanyID, branch.ID).
		Order("name").Find(&categories)

	// Get available menus
	var menus []models.Menu
	database.DB.Where("company_id = ? AND (branch_id = ? OR branch_id IS NULL) AND is_available = true", branch.CompanyID, branch.ID).
		Preload("Category").Order("name").Find(&menus)

	// Group by category
	catMap := make(map[uint]*PublicCategoryWithMenus)
	for _, cat := range categories {
		catMap[cat.ID] = &PublicCategoryWithMenus{
			ID:    cat.ID,
			Name:  cat.Name,
			Items: []PublicMenuItem{},
		}
	}

	for _, m := range menus {
		item := PublicMenuItem{
			ID:          m.ID,
			Name:        m.Name,
			Description: m.Description,
			Price:       m.Price,
			ImageURL:    m.ImageURL,
			IsAvailable: m.IsAvailable,
			CategoryID:  m.CategoryID,
		}
		if cat, ok := catMap[m.CategoryID]; ok {
			cat.Items = append(cat.Items, item)
		}
	}

	// Convert to ordered slice, exclude empty categories
	var result []PublicCategoryWithMenus
	for _, cat := range categories {
		if cm, ok := catMap[cat.ID]; ok && len(cm.Items) > 0 {
			result = append(result, *cm)
		}
	}

	// Get operating status
	openTime, closeTime, isOpen := getBranchOperatingStatus(branch.ID)

	c.JSON(http.StatusOK, gin.H{
		"branch": gin.H{
			"id":         branch.ID,
			"name":       branch.Name,
			"code":       branch.Code,
			"address":    branch.Address,
			"phone":      branch.Phone,
			"is_open":    isOpen,
			"open_time":  openTime,
			"close_time": closeTime,
		},
		"categories": result,
	})
}

// ─── Public Create Order (Online) ─────────────────────────────────────────────

type PublicOrderRequest struct {
	BranchID       uint                   `json:"branch_id" binding:"required"`
	CustomerName   string                 `json:"customer_name" binding:"required"`
	CustomerPhone  string                 `json:"customer_phone"`
	DeliveryMethod string                 `json:"delivery_method"` // Pickup, Delivery, Dine In
	PaymentMethod  string                 `json:"payment_method"`
	ShippingAddress string                `json:"shipping_address"`
	ShippingFee    float64                `json:"shipping_fee"`
	PromoID        *uint                  `json:"promo_id"`
	UsePoints      bool                   `json:"use_points"`
	Notes          string                 `json:"notes"`
	Items          []PublicOrderItemInput `json:"items" binding:"required"`
}

type PublicOrderItemInput struct {
	MenuID   uint   `json:"menu_id" binding:"required"`
	Quantity int    `json:"quantity" binding:"required"`
	Notes    string `json:"notes"`
}

func PublicCreateOrder(c *gin.Context) {
	var req PublicOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate branch
	var branch models.Branch
	if err := database.DB.First(&branch, req.BranchID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Branch not found"})
		return
	}

	// Check if branch is open
	_, _, isOpen := getBranchOperatingStatus(branch.ID)
	if !isOpen {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Toko sedang tutup. Silakan pesan pada jam operasional."})
		return
	}

	// Build order items and calculate totals
	var total float64
	var orderItems []models.OrderItem

	for _, item := range req.Items {
		var menu models.Menu
		if err := database.DB.First(&menu, item.MenuID).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Menu ID %d not found", item.MenuID)})
			return
		}
		if !menu.IsAvailable {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Menu '%s' sedang tidak tersedia", menu.Name)})
			return
		}

		subtotal := menu.Price * float64(item.Quantity)
		orderItems = append(orderItems, models.OrderItem{
			MenuID:   item.MenuID,
			Quantity: item.Quantity,
			Price:    menu.Price,
			Subtotal: subtotal,
			Notes:    item.Notes,
		})
		total += subtotal
	}

	// Get customer_user_id if logged in
	customerUserID, _ := c.Get("customerUserID")
	var finalCustomerUserID *uint
	if customerUserID != nil {
		id := customerUserID.(uint)
		finalCustomerUserID = &id
	}

	// Get dynamic settings for tax/service
	var settings []models.SystemSetting
	database.DB.Where("branch_id = ? OR branch_id IS NULL", branch.ID).Find(&settings)
	settingsMap := make(map[string]string)
	for _, s := range settings {
		settingsMap[s.Key] = s.Value
	}

	taxPct := 0.1 // Default 10%
	if val, ok := settingsMap["tax_pct"]; ok {
		taxPct, _ = strconv.ParseFloat(val, 64)
		taxPct = taxPct / 100
	}

	servicePct := 0.0
	if val, ok := settingsMap["service_charge_pct"]; ok {
		servicePct, _ = strconv.ParseFloat(val, 64)
		servicePct = servicePct / 100
	}

	serviceCharge := total * servicePct
	tax := (total + serviceCharge) * taxPct

	// Check if global promo is enabled for this customer, and calculate personal promo
	isGlobalEnabled := true
	personalDiscount := 0.0
	if finalCustomerUserID != nil {
		var cUser models.CustomerUser
		if err := database.DB.Preload("Customer").First(&cUser, *finalCustomerUserID).Error; err == nil && cUser.Customer != nil {
			isGlobalEnabled = cUser.Customer.IsGlobalPromoEnabled
			if cUser.Customer.PersonalPromoType == "percentage" {
				personalDiscount = total * (cUser.Customer.PersonalPromoValue / 100)
			} else if cUser.Customer.PersonalPromoType == "flat" {
				personalDiscount = cUser.Customer.PersonalPromoValue
			}
		}
	}

	discount := 0.0
	if req.PromoID != nil && isGlobalEnabled {
		var promo models.Promo
		if err := database.DB.First(&promo, req.PromoID).Error; err == nil {
			if promo.IsActive && time.Now().After(promo.StartDate) && time.Now().Before(promo.EndDate) {
				if total >= promo.MinOrder {
					if promo.Type == "percentage" {
						discount = total * (promo.Value / 100)
						if promo.MaxDiscount > 0 && discount > promo.MaxDiscount {
							discount = promo.MaxDiscount
						}
					} else {
						discount = promo.Value
					}
				}
			}
		}
	}

	// Point Redemption Logic
	pointsDiscount := 0.0
	var pointsToDeduct int
	if req.UsePoints && finalCustomerUserID != nil {
		var cUser models.CustomerUser
		if err := database.DB.Preload("Customer").First(&cUser, *finalCustomerUserID).Error; err == nil && cUser.Customer != nil {
			availablePoints := cUser.Customer.LoyaltyPoints
			// Conversion: 1 point = Rp 1
			maxPointsUsable := int(total - discount - personalDiscount)
			if maxPointsUsable < 0 {
				maxPointsUsable = 0
			}
			if availablePoints > maxPointsUsable {
				pointsToDeduct = maxPointsUsable
			} else {
				pointsToDeduct = availablePoints
			}
			pointsDiscount = float64(pointsToDeduct)
		}
	}

	deliveryMethod := req.DeliveryMethod
	if deliveryMethod == "" {
		deliveryMethod = "Pickup"
	}

	// Find a default system user for online orders (or use first user)
	var systemUser models.User
	database.DB.Where("company_id = ?", branch.CompanyID).First(&systemUser)
	userID := systemUser.ID
	if userID == 0 {
		userID = 1
	}

	order := models.Order{
		CompanyID:           branch.CompanyID,
		BranchID:            branch.ID,
		UserID:              userID,
		CustomerName:        req.CustomerName,
		Status:              "Pending",
		TotalAmount:         total + tax + serviceCharge + req.ShippingFee - discount - personalDiscount - pointsDiscount,
		TaxAmount:           tax,
		ServiceChargeAmount: serviceCharge,
		DiscountAmount:      discount + personalDiscount + pointsDiscount,
		ShippingFee:         req.ShippingFee,
		PromoID:             req.PromoID,
		Notes:               req.Notes,
		Items:               orderItems,
		OrderSource:         "Online",
		DeliveryMethod:      deliveryMethod,
		PaymentMethod:       req.PaymentMethod,
		ShippingAddress:     req.ShippingAddress,
		CustomerUserID:      finalCustomerUserID,
	}

	// Optionally create or link customer
	var customer models.Customer
	if req.CustomerPhone != "" {
		err := database.DB.Where("phone = ? AND company_id = ?", req.CustomerPhone, branch.CompanyID).First(&customer).Error
		if err != nil {
			// Create new customer
			customer = models.Customer{
				CompanyID: branch.CompanyID,
				BranchID:  &branch.ID,
				Name:      req.CustomerName,
				Phone:     req.CustomerPhone,
			}
			database.DB.Create(&customer)
		}
		order.CustomerID = &customer.ID
		order.CustomerName = customer.Name
	}

	tx := database.DB.Begin()
	if err := tx.Create(&order).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat pesanan"})
		return
	}

	// Deduct points if used
	if pointsToDeduct > 0 {
		tx.Model(&models.Customer{}).Where("id = ?", order.CustomerID).
			Update("loyalty_points", gorm.Expr("loyalty_points - ?", pointsToDeduct))
	}

	// Award loyalty points (1 point per 10k of final amount)
	if order.CustomerID != nil {
		pointsEarned := int(order.TotalAmount / 10000)
		if pointsEarned > 0 {
			tx.Model(&models.Customer{}).Where("id = ?", order.CustomerID).
				Update("loyalty_points", gorm.Expr("loyalty_points + ?", pointsEarned))
		}
	}

	tx.Commit()

	c.JSON(http.StatusCreated, gin.H{
		"order_id": order.ID,
		"status":   order.Status,
		"total":    order.TotalAmount,
		"discount": order.DiscountAmount,
		"message":  "Pesanan berhasil dibuat! Silakan tunggu konfirmasi dari toko.",
	})
}

// ─── Public Order Status ──────────────────────────────────────────────────────

func PublicGetOrderStatus(c *gin.Context) {
	id := c.Param("id")
	var order models.Order
	if err := database.DB.Preload("Items.Menu").Preload("Branch.Company").First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pesanan tidak ditemukan"})
		return
	}

	type ItemResponse struct {
		Name     string  `json:"name"`
		Quantity int     `json:"quantity"`
		Price    float64 `json:"price"`
		Subtotal float64 `json:"subtotal"`
		IsReady  bool    `json:"is_ready"`
	}

	var items []ItemResponse
	for _, item := range order.Items {
		items = append(items, ItemResponse{
			Name:     item.Menu.Name,
			Quantity: item.Quantity,
			Price:    item.Price,
			Subtotal: item.Subtotal,
			IsReady:  item.IsReady,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"order_id":        order.ID,
		"status":          order.Status,
		"customer_name":   order.CustomerName,
		"total_amount":    order.TotalAmount,
		"tax_amount":      order.TaxAmount,
		"service_charge":  order.ServiceChargeAmount,
		"notes":           order.Notes,
		"order_source":    order.OrderSource,
		"delivery_method": order.DeliveryMethod,
		"branch_name":     order.Branch.Name,
		"company_code":    order.Branch.Company.Code,
		"created_at":      order.CreatedAt,
		"items":           items,
	})
}

// ─── Public Company Info ──────────────────────────────────────────────────────

func PublicGetCompanyInfo(c *gin.Context) {
	code := c.Param("code")
	var company models.Company
	err := database.DB.Where("code = ?", code).First(&company).Error
	if err != nil {
		err = database.DB.Where("id = ?", code).First(&company).Error
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Company not found"})
			return
		}
	}

	// Fetch theme settings from system_settings
	var settings []models.SystemSetting
	database.DB.Where("company_id = ? AND branch_id IS NULL", company.ID).Find(&settings)
	
	theme := make(map[string]string)
	for _, s := range settings {
		if s.Key == "primary_color" || s.Key == "secondary_color" || s.Key == "accent_color" {
			theme[s.Key] = s.Value
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       company.ID,
		"name":     company.Name,
		"code":     company.Code,
		"logo_url": company.LogoURL,
		"address":  company.Address,
		"phone":    company.Phone,
		"email":    company.Email,
		"theme":    theme,
	})
}

func PublicGetPromos(c *gin.Context) {
	companyID := c.Query("company_id")
	if companyID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "company_id is required"})
		return
	}

	var promos []models.Promo
	now := time.Now()
	database.DB.Where("company_id = ? AND is_active = true AND start_date <= ? AND end_date >= ?", 
		companyID, now, now).Find(&promos)

	c.JSON(http.StatusOK, promos)
}

// ─── Helper: Get Branch Operating Status ──────────────────────────────────────

func getBranchOperatingStatus(branchID uint) (openTime string, closeTime string, isOpen bool) {
	var branch models.Branch
	if err := database.DB.Select("open_time, close_time").First(&branch, branchID).Error; err != nil {
		openTime = "08:00"
		closeTime = "22:00"
	} else {
		// PostgreSQL TIME type usually comes as HH:MM:SS
		openTime = branch.OpenTime
		closeTime = branch.CloseTime

		// Clean up seconds if present
		if len(openTime) > 5 {
			openTime = openTime[:5]
		}
		if len(closeTime) > 5 {
			closeTime = closeTime[:5]
		}
	}

	// Check current time
	loc, _ := time.LoadLocation("Asia/Jakarta")
	now := time.Now().In(loc)
	currentMinutes := now.Hour()*60 + now.Minute()

	openParts := parseTime(openTime)
	closeParts := parseTime(closeTime)

	isOpen = currentMinutes >= openParts && currentMinutes <= closeParts
	return
}

// ─── Customer Auth ────────────────────────────────────────────────────────────

type CustomerRegisterRequest struct {
	CompanyID uint   `json:"company_id" binding:"required"`
	Username  string `json:"username" binding:"required"`
	Password  string `json:"password" binding:"required"`
	FullName  string `json:"full_name" binding:"required"`
	Email     string `json:"email"`
	Phone     string `json:"phone"`
	Address   string `json:"address"`
}

func PublicRegisterCustomer(c *gin.Context) {
	var req CustomerRegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if username exists
	var existing models.CustomerUser
	if err := database.DB.Where("username = ?", req.Username).First(&existing).Error; err == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Username sudah digunakan"})
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)

	// Create customer record first
	customer := models.Customer{
		CompanyID: req.CompanyID,
		Name:      req.FullName,
		Email:     req.Email,
		Phone:     req.Phone,
		Address:   req.Address,
	}
	database.DB.Create(&customer)

	customerUser := models.CustomerUser{
		CompanyID:    req.CompanyID,
		CustomerID:   &customer.ID,
		Username:     req.Username,
		PasswordHash: string(hash),
		FullName:     req.FullName,
		Email:        req.Email,
		Phone:        req.Phone,
	}

	if err := database.DB.Create(&customerUser).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal registrasi"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Registrasi berhasil! Silakan login."})
}

type CustomerLoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func PublicLoginCustomer(c *gin.Context) {
	var req CustomerLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.CustomerUser
	if err := database.DB.Where("username = ?", req.Username).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Username atau password salah"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Username atau password salah"})
		return
	}

	// Generate JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"customer_user_id": user.ID,
		"role":             "Customer",
		"company_id":       user.CompanyID,
		"exp":              time.Now().Add(time.Hour * 720).Unix(), // 30 days
	})

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "supersecretkey"
	}

	tokenString, _ := token.SignedString([]byte(secret))

	c.JSON(http.StatusOK, gin.H{
		"token": tokenString,
		"user": gin.H{
			"id":        user.ID,
			"username":  user.Username,
			"full_name": user.FullName,
		},
	})
}

func PublicGetOrderHistory(c *gin.Context) {
	customerUserID, _ := c.Get("customerUserID")
	var orders []models.Order
	database.DB.Where("customer_user_id = ?", customerUserID).Order("created_at DESC").Preload("Items.Menu").Preload("Branch").Find(&orders)
	c.JSON(http.StatusOK, orders)
}

func PublicGetCustomerMe(c *gin.Context) {
	customerUserID, _ := c.Get("customerUserID")
	var user models.CustomerUser
	if err := database.DB.Preload("Customer").First(&user, customerUserID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}
	c.JSON(http.StatusOK, user)
}

func parseTime(t string) int {
	h, m := 0, 0
	fmt.Sscanf(t, "%d:%d", &h, &m)
	return h*60 + m
}
