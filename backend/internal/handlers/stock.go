package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetStockHistory(c *gin.Context) {
	var history []models.StockHistory
	
	ingredientID := c.Query("ingredient_id")
	typeFilter := c.Query("type")
	
	db := database.DB.Scopes(middleware.GetQueryScope(c)).
		Preload("Ingredient").
		Preload("Order").
		Preload("Branch").
		Preload("User")

	if ingredientID != "" {
		db = db.Where("ingredient_id = ?", ingredientID)
	}
	
	if typeFilter != "" {
		db = db.Where("type = ?", typeFilter)
	}

	// Pagination
	var total int64
	db.Model(&models.StockHistory{}).Count(&total)
	
	limit := 50
	offset := 0
	
	if err := db.Order("created_at desc").Limit(limit).Offset(offset).Find(&history).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stock history"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"rows":  history,
		"total": total,
	})
}
