package handlers

import (
	"net/http"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetProfile(c *gin.Context) {
	userIDRaw, _ := c.Get("userID")
	userID := userIDRaw.(uint)

	var user models.User
	if err := database.DB.Preload("Role").Preload("Branch").First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":        user.ID,
		"full_name": user.FullName,
		"username":  user.Username,
		"role":      user.Role.Name,
		"role_id":   user.RoleID,
		"branch":    user.Branch,
		"branch_id": user.BranchID,
		"is_active": user.IsActive,
	})
}
