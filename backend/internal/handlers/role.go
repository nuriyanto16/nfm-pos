package handlers

import (
	"net/http"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetRoles(c *gin.Context) {
	var roles []models.Role
	if err := database.DB.Preload("Menus").Find(&roles).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch roles"})
		return
	}
	c.JSON(http.StatusOK, roles)
}

func CreateRole(c *gin.Context) {
	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		MenuIDs     []uint `json:"menu_ids"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	role := models.Role{
		Name:        req.Name,
		Description: req.Description,
	}

	if err := database.DB.Create(&role).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create role"})
		return
	}

	if len(req.MenuIDs) > 0 {
		var menus []models.SidebarMenu
		database.DB.Find(&menus, req.MenuIDs)
		database.DB.Model(&role).Association("Menus").Replace(menus)
	}

	c.JSON(http.StatusCreated, role)
}

func UpdateRole(c *gin.Context) {
	id := c.Param("id")
	var role models.Role
	if err := database.DB.First(&role, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Role not found"})
		return
	}

	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		MenuIDs     []uint `json:"menu_ids"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{}
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}

	if err := database.DB.Model(&role).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update role"})
		return
	}

	if req.MenuIDs != nil {
		var menus []models.SidebarMenu
		database.DB.Find(&menus, req.MenuIDs)
		database.DB.Model(&role).Association("Menus").Replace(menus)
	}

	// Fetch again with menus preloaded to return to frontend
	database.DB.Preload("Menus").First(&role, role.ID)
	c.JSON(http.StatusOK, role)
}

func DeleteRole(c *gin.Context) {
	id := c.Param("id")
	// Check if any user uses this role
	var count int64
	database.DB.Model(&models.User{}).Where("role_id = ?", id).Count(&count)
	if count > 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "Cannot delete role, it is still assigned to users"})
		return
	}

	var role models.Role
	if err := database.DB.First(&role, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Role not found"})
		return
	}
	if err := database.DB.Delete(&role).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete role"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Role deleted successfully"})
}
