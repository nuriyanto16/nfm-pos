package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetStockHistory(c *gin.Context) {
	var history []models.StockHistory
	branchID, _ := c.Get("branchID")
	
	ingredientID := c.Query("ingredient_id")
	
	db := database.DB.Where("stock_histories.branch_id = ?", branchID).
		Preload("Ingredient").
		Preload("Order")

	if ingredientID != "" {
		db = db.Where("ingredient_id = ?", ingredientID)
	}

	if err := db.Order("created_at desc").Limit(100).Find(&history).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stock history"})
		return
	}

	c.JSON(http.StatusOK, history)
}
