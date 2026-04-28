package handlers

import (
	"net/http"
	"time"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetPromos(c *gin.Context) {
	var promos []models.Promo
	db := database.DB.Model(&models.Promo{}).Scopes(middleware.GetQueryScope(c))

	pagination, err := Paginate(c, db.Order("created_at desc"), &promos)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch promos"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

// GetActivePromos returns promos that are active and within date range
func GetActivePromos(c *gin.Context) {
	var promos []models.Promo
	now := time.Now()
	db := database.DB.Scopes(middleware.GetQueryScope(c)).Where("is_active = true AND start_date <= ? AND end_date >= ?", now, now)

	if err := db.Find(&promos).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch active promos"})
		return
	}
	c.JSON(http.StatusOK, promos)
}

func CreatePromo(c *gin.Context) {
	var promo models.Promo
	if err := c.ShouldBindJSON(&promo); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if companyID, exists := c.Get("companyID"); exists {
		promo.CompanyID = companyID.(uint)
	}
	if err := database.DB.Create(&promo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create promo"})
		return
	}
	c.JSON(http.StatusCreated, promo)
}

func UpdatePromo(c *gin.Context) {
	id := c.Param("id")
	var promo models.Promo
	if err := database.DB.First(&promo, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Promo not found"})
		return
	}

	var req models.Promo
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	req.ID = promo.ID
	req.CreatedAt = promo.CreatedAt
	if err := database.DB.Save(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update promo"})
		return
	}
	c.JSON(http.StatusOK, req)
}

func TogglePromoStatus(c *gin.Context) {
	id := c.Param("id")
	var promo models.Promo
	if err := database.DB.First(&promo, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Promo not found"})
		return
	}
	if err := database.DB.Model(&promo).Update("is_active", !promo.IsActive).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to toggle promo status"})
		return
	}
	promo.IsActive = !promo.IsActive
	c.JSON(http.StatusOK, promo)
}

func DeletePromo(c *gin.Context) {
	id := c.Param("id")
	var promo models.Promo
	if err := database.DB.First(&promo, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Promo not found"})
		return
	}
	if err := database.DB.Delete(&promo).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete promo"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Promo deleted successfully"})
}
