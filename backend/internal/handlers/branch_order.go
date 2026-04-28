package handlers

import (
	"fmt"
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"
	"time"

	"github.com/gin-gonic/gin"
)

func GetBranchOrders(c *gin.Context) {
	var orders []models.BranchOrder
	db := database.DB.Model(&models.BranchOrder{}).Preload("Branch").Preload("Items.Ingredient").Scopes(middleware.GetQueryScope(c))

	// Optional filters
	if status := c.Query("status"); status != "" {
		db = db.Where("status = ?", status)
	}

	if excludeUsed := c.Query("exclude_used"); excludeUsed == "true" {
		db = db.Joins("LEFT JOIN goods_receipts ON goods_receipts.branch_order_id = branch_orders.id AND goods_receipts.status != 'Cancelled'").
			Where("goods_receipts.id IS NULL")
	}

	pagination, err := Paginate(c, db.Order("created_at desc"), &orders)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch branch orders"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func GetBranchOrderByID(c *gin.Context) {
	id := c.Param("id")
	var order models.BranchOrder
	if err := database.DB.Preload("Branch").Preload("Items.Ingredient").First(&order, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}
	c.JSON(http.StatusOK, order)
}

func CreateBranchOrder(c *gin.Context) {
	var order models.BranchOrder
	if err := c.ShouldBindJSON(&order); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Set metadata
	if companyID, exists := c.Get("companyID"); exists {
		order.CompanyID = companyID.(uint)
	}
	
	// Set Branch ID (Priority: Input > Context > First available branch)
	branchID, _ := c.Get("branchID")
	if order.BranchID == 0 {
		if branchID != nil && branchID.(uint) != 0 {
			order.BranchID = branchID.(uint)
		} else {
			// If admin (no branch_id in context), pick first branch from company
			var firstBranch models.Branch
			database.DB.Where("company_id = ?", order.CompanyID).First(&firstBranch)
			order.BranchID = firstBranch.ID
		}
	}

	order.OrderDate = time.Now()
	order.Status = "Pending"
	order.OrderNo = fmt.Sprintf("BO-%d%02d%02d-%04d", 
		order.OrderDate.Year(), order.OrderDate.Month(), order.OrderDate.Day(), 
		time.Now().Unix()%10000)

	if err := database.DB.Create(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create order"})
		return
	}

	c.JSON(http.StatusCreated, order)
}

func UpdateBranchOrderStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status string `json:"status" binding:"required"`
		Items  []struct {
			ID          uint    `json:"id"`
			ApprovedQty float64 `json:"approved_qty"`
		} `json:"items"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tx := database.DB.Begin()
	var order models.BranchOrder
	if err := tx.First(&order, id).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	order.Status = req.Status
	if err := tx.Save(&order).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update status"})
		return
	}

	// Update approved quantities if provided
	for _, itemReq := range req.Items {
		tx.Model(&models.BranchOrderItem{}).Where("id = ?", itemReq.ID).Update("approved_qty", itemReq.ApprovedQty)
	}

	tx.Commit()
	c.JSON(http.StatusOK, order)
}
