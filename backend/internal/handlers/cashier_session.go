package handlers

import (
	"net/http"
	"time"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetCashierSessions(c *gin.Context) {
	var sessions []models.CashierSession
	db := database.DB.Scopes(middleware.GetQueryScope(c)).Preload("User")

	pagination, err := Paginate(c, db.Order("open_time desc"), &sessions)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch sessions"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func GetActiveCashierSession(c *gin.Context) {
	userID, _ := c.Get("userID")
	var session models.CashierSession
	err := database.DB.Preload("User").Where("user_id = ? AND status = 'Open'", userID).First(&session).Error
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"session": nil})
		return
	}
	c.JSON(http.StatusOK, session)
}

func GetActiveCashierSessionSummary(c *gin.Context) {
	userID, _ := c.Get("userID")
	var session models.CashierSession
	err := database.DB.Where("user_id = ? AND status = 'Open'", userID).First(&session).Error
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No open session"})
		return
	}

	var totalSales float64
	var totalCashSales float64

	// Calculate total sales
	database.DB.Model(&models.Order{}).
		Where("created_at >= ? AND status = 'Selesai' AND user_id = ?", session.OpenTime, userID).
		Select("COALESCE(SUM(total_amount), 0)").
		Scan(&totalSales)

	// Calculate ONLY CASH sales (amount_paid - change)
	database.DB.Table("orders").
		Select("COALESCE(SUM(payments.amount_paid - payments.change), 0)").
		Joins("join payments on payments.order_id = orders.id").
		Where("orders.created_at >= ? AND orders.status = 'Selesai' AND orders.user_id = ? AND payments.payment_method = 'Tunai'", session.OpenTime, userID).
		Scan(&totalCashSales)

	expectedCash := session.InitialCash + totalCashSales

	c.JSON(http.StatusOK, gin.H{
		"session_id":       session.ID,
		"initial_cash":     session.InitialCash,
		"total_sales":      totalSales,
		"total_cash_sales": totalCashSales,
		"expected_cash":    expectedCash,
	})
}

func OpenCashierSession(c *gin.Context) {
	userID, _ := c.Get("userID")

	// Check if already open
	var existing models.CashierSession
	if err := database.DB.Where("user_id = ? AND status = 'Open'", userID).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Session already open", "session": existing})
		return
	}

	var req struct {
		InitialCash float64 `json:"initial_cash"`
		Notes       string  `json:"notes"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get branch from user
	branchID, _ := c.Get("branchID")
	var finalBranchID uint
	if branchID != nil {
		finalBranchID = branchID.(uint)
	}

	session := models.CashierSession{
		BranchID:    finalBranchID,
		UserID:      userID.(uint),
		OpenTime:    time.Now(),
		InitialCash: req.InitialCash,
		Notes:       req.Notes,
		Status:      "Open",
	}

	if err := database.DB.Create(&session).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open session"})
		return
	}

	database.DB.Preload("User").First(&session, session.ID)
	c.JSON(http.StatusCreated, session)
}

func CloseCashierSession(c *gin.Context) {
	id := c.Param("id")
	var session models.CashierSession
	if err := database.DB.First(&session, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}
	if session.Status == "Closed" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Session already closed"})
		return
	}

	var req struct {
		ClosingCash float64 `json:"closing_cash"`
		Notes       string  `json:"notes"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Calculate total sales from orders in this period
	var totalSales float64
	var totalOrders int64
	database.DB.Model(&models.Order{}).
		Where("created_at >= ? AND status = 'Selesai'", session.OpenTime).
		Select("COALESCE(SUM(total_amount), 0)").
		Scan(&totalSales)
	database.DB.Model(&models.Order{}).
		Where("created_at >= ? AND status = 'Selesai'", session.OpenTime).
		Count(&totalOrders)

	// Calculate ONLY CASH sales
	var totalCashSales float64
	database.DB.Table("orders").
		Select("COALESCE(SUM(payments.amount_paid - payments.change), 0)").
		Joins("join payments on payments.order_id = orders.id").
		Where("orders.created_at >= ? AND orders.status = 'Selesai' AND orders.user_id = ? AND payments.payment_method = 'Tunai'", session.OpenTime, session.UserID).
		Scan(&totalCashSales)

	closeTime := time.Now()
	updates := map[string]interface{}{
		"close_time":   closeTime,
		"closing_cash": req.ClosingCash,
		"total_sales":  totalSales, // We still record total sales
		"total_orders": int(totalOrders),
		"status":       "Closed",
	}
	if req.Notes != "" {
		updates["notes"] = req.Notes
	}

	if err := database.DB.Model(&session).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to close session"})
		return
	}

	database.DB.Preload("User").First(&session, session.ID)
	c.JSON(http.StatusOK, session)
}
