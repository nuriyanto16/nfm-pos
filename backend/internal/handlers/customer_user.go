package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

func GetCustomerUsers(c *gin.Context) {
	companyID, _ := c.Get("companyID")
	var users []models.CustomerUser
	database.DB.Where("company_id = ?", companyID).Preload("Customer").Find(&users)
	c.JSON(http.StatusOK, users)
}

func CreateCustomerUser(c *gin.Context) {
	companyID, _ := c.Get("companyID")
	var input struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
		FullName string `json:"full_name" binding:"required"`
		Email    string `json:"email"`
		Phone    string `json:"phone"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)

	user := models.CustomerUser{
		CompanyID:    companyID.(uint),
		Username:     input.Username,
		PasswordHash: string(hash),
		FullName:     input.FullName,
		Email:        input.Email,
		Phone:        input.Phone,
		IsActive:     true,
	}

	if err := database.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat user: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, user)
}

func UpdateCustomerUser(c *gin.Context) {
	id := c.Param("id")
	companyID, _ := c.Get("companyID")

	var user models.CustomerUser
	if err := database.DB.Where("id = ? AND company_id = ?", id, companyID).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User tidak ditemukan"})
		return
	}

	var input struct {
		FullName string `json:"full_name"`
		Email    string `json:"email"`
		Phone    string `json:"phone"`
		IsActive bool   `json:"is_active"`
		Password string `json:"password"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user.FullName = input.FullName
	user.Email = input.Email
	user.Phone = input.Phone
	user.IsActive = input.IsActive

	if input.Password != "" {
		hash, _ := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
		user.PasswordHash = string(hash)
	}

	database.DB.Save(&user)
	c.JSON(http.StatusOK, user)
}

func DeleteCustomerUser(c *gin.Context) {
	id := c.Param("id")
	companyID, _ := c.Get("companyID")

	if err := database.DB.Where("id = ? AND company_id = ?", id, companyID).Delete(&models.CustomerUser{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menghapus user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User berhasil dihapus"})
}
