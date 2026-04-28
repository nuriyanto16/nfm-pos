package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetBranches(c *gin.Context) {
	var branches []models.Branch
	query := database.DB.Model(&models.Branch{}).Scopes(middleware.GetQueryScope(c))

	// Basic filter
	isActive := c.Query("active")
	if isActive != "" {
		query = query.Where("is_active = ?", isActive == "true")
	}

	if err := query.Find(&branches).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch branches"})
		return
	}

	c.JSON(http.StatusOK, branches)
}

func GetBranchByID(c *gin.Context) {
	id := c.Param("id")
	var branch models.Branch
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).First(&branch, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Branch not found"})
		return
	}
	c.JSON(http.StatusOK, branch)
}

func CreateBranch(c *gin.Context) {
	var branch models.Branch
	if err := c.ShouldBindJSON(&branch); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Create(&branch).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create branch"})
		return
	}
	c.JSON(http.StatusCreated, branch)
}

func UpdateBranch(c *gin.Context) {
	id := c.Param("id")
	var branch models.Branch
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).First(&branch, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Branch not found"})
		return
	}

	if err := c.ShouldBindJSON(&branch); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Save(&branch).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update branch"})
		return
	}
	c.JSON(http.StatusOK, branch)
}

func DeleteBranch(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Delete(&models.Branch{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete branch"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Branch deleted successfully"})
}
