package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetSidebarMenus(c *gin.Context) {
	var menus []models.SidebarMenu
	if err := database.DB.Order("sort_order ASC").Find(&menus).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch menus"})
		return
	}
	c.JSON(http.StatusOK, menus)
}

func CreateSidebarMenu(c *gin.Context) {
	var menu models.SidebarMenu
	if err := c.ShouldBindJSON(&menu); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := database.DB.Create(&menu).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create menu"})
		return
	}
	c.JSON(http.StatusCreated, menu)
}

func UpdateSidebarMenu(c *gin.Context) {
	id := c.Param("id")
	var menu models.SidebarMenu
	if err := database.DB.First(&menu, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Menu not found"})
		return
	}
	if err := c.ShouldBindJSON(&menu); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	database.DB.Save(&menu)
	c.JSON(http.StatusOK, menu)
}

func DeleteSidebarMenu(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Delete(&models.SidebarMenu{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete menu"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Menu deleted"})
}
