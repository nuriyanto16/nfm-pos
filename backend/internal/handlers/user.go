package handlers

import (
	"net/http"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type CreateUserRequest struct {
	Username string `json:"username" binding:"required"`
	FullName string `json:"full_name"`
	Password string `json:"password" binding:"required,min=6"`
	RoleID   uint   `json:"role_id" binding:"required"`
	BranchID *uint  `json:"branch_id"`
}

type UpdateUserRequest struct {
	FullName string `json:"full_name"`
	RoleID   uint   `json:"role_id"`
	BranchID *uint  `json:"branch_id"`
	IsActive *bool  `json:"is_active"`
}

type ChangePasswordRequest struct {
	Password string `json:"password" binding:"required,min=6"`
}

func GetUsers(c *gin.Context) {
	var users []models.User
	db := database.DB.Model(&models.User{}).Scopes(middleware.GetQueryScope(c)).Preload("Role").Preload("Branch")

	pagination, err := Paginate(c, db, &users)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func CreateUser(c *gin.Context) {
	var req CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Default to user's own branch if not specified (and not admin)
	branchID, _ := c.Get("branchID")
	finalBranchID := req.BranchID
	if finalBranchID == nil && branchID != nil {
		bid := branchID.(uint)
		finalBranchID = &bid
	}

	user := models.User{
		FullName:     req.FullName,
		Username:     req.Username,
		PasswordHash: string(hash),
		RoleID:       req.RoleID,
		BranchID:     finalBranchID,
		IsActive:     true,
	}

	if companyID, exists := c.Get("companyID"); exists {
		user.CompanyID = companyID.(uint)
	} else {
		user.CompanyID = 1 // Fallback
	}

	if err := database.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user, username may already exist"})
		return
	}

	database.DB.Preload("Role").First(&user, user.ID)
	c.JSON(http.StatusCreated, user)
}

func UpdateUser(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	var req UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{}
	if req.FullName != "" {
		updates["full_name"] = req.FullName
	}
	if req.RoleID != 0 {
		updates["role_id"] = req.RoleID
	}
	if req.IsActive != nil {
		updates["is_active"] = *req.IsActive
	}
	if req.BranchID != nil {
		updates["branch_id"] = req.BranchID
	}

	if err := database.DB.Model(&user).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
		return
	}

	database.DB.Preload("Role").First(&user, user.ID)
	c.JSON(http.StatusOK, user)
}

func ChangeUserPassword(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	if err := database.DB.Model(&user).Update("password_hash", string(hash)).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to change password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully"})
}

func DeleteUser(c *gin.Context) {
	id := c.Param("id")
	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	if err := database.DB.Delete(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete user"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "User deleted successfully"})
}
