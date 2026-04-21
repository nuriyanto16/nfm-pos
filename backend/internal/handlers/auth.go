package handlers

import (
	"net/http"
	"os"
	"time"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type LoginRequest struct {
	Username     string `json:"username" binding:"required"`
	Password     string `json:"password" binding:"required"`
	CaptchaID    string `json:"captcha_id" binding:"required"`
	CaptchaValue string `json:"captcha_value" binding:"required"`
}

func Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify Captcha
	if !VerifyCaptcha(req.CaptchaID, req.CaptchaValue) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid captcha"})
		return
	}

	var user models.User
	if err := database.DB.Preload("Role").Where("username = ?", req.Username).First(&user).Error; err != nil {
		// Wait, if no user found, for testing let's allow creating dummy admin if users table is empty
		var count int64
		database.DB.Model(&models.User{}).Count(&count)
		if count == 0 && req.Username == "admin" && req.Password == "admin" {
			hash, _ := bcrypt.GenerateFromPassword([]byte("admin"), bcrypt.DefaultCost)
			user = models.User{
				Username:     "admin",
				PasswordHash: string(hash),
				RoleID:       1, // Assuming 1 is Admin from init.sql
			}
			database.DB.Create(&user)
			database.DB.Preload("Role").First(&user, user.ID)
		} else {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid username or password"})
			return
		}
	}

	if user.Role.Name == "" {
		// Ensure Role is preloaded if it was missing for some reason
		database.DB.Preload("Role").First(&user, user.ID)
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid username or password"})
		return
	}

	// Generate JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":   user.ID,
		"role":      user.Role.Name,
		"branch_id": user.BranchID,
		"exp":       time.Now().Add(time.Hour * 72).Unix(),
	})

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "supersecretkey" // Default fallback
	}
	
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": tokenString,
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"role":     user.Role.Name,
		},
	})
}
