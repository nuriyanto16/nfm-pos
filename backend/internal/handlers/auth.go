package handlers

import (
	"net/http"
	"os"
	"strings"
	"time"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
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
				CompanyID:    1, // Default to first company
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
		"user_id":    user.ID,
		"role":       user.Role.Name,
		"branch_id":  user.BranchID,
		"company_id": user.CompanyID,
		"exp":        time.Now().Add(time.Hour * 72).Unix(),
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

func shouldShowMenuForCategory(path string, isHeader bool, title string, category string) bool {
	cat := strings.ToLower(category)
	p := strings.ToLower(path)

	// Resto-specific category match
	isRestoCompany := strings.Contains(cat, "resto") || strings.Contains(cat, "f&b") || cat == ""

	// Retail-specific category match (includes retail/toko/fashion/lainnya)
	isRetailCompany := strings.Contains(cat, "retail") || strings.Contains(cat, "toko") || strings.Contains(cat, "fashion") || strings.Contains(cat, "lain")

	// Jasa-specific category match
	isJasaCompany := strings.Contains(cat, "jasa") || strings.Contains(cat, "laundry") || strings.Contains(cat, "salon") || strings.Contains(cat, "cuci")

	// If Resto company: hide other POS modules
	if isRestoCompany {
		if strings.Contains(p, "type=fashion") || strings.Contains(p, "type=retail") || strings.Contains(p, "type=jasa") {
			return false
		}
	}

	// If Retail / Fashion company: hide Resto and Jasa specific modules
	if isRetailCompany {
		if strings.Contains(p, "type=resto") || strings.Contains(p, "type=jasa") ||
			strings.Contains(p, "kitchen") || strings.Contains(p, "monitoring-tables") ||
			strings.Contains(p, "layout-tables") || strings.Contains(p, "manage-tables") {
			return false
		}
		// For retail, if it's fashion type, show fashion POS. If it's retail type, show retail POS.
		if strings.Contains(cat, "fashion") && strings.Contains(p, "type=retail") {
			return false
		}
		if (strings.Contains(cat, "retail") || strings.Contains(cat, "toko")) && strings.Contains(p, "type=fashion") {
			return false
		}
	}

	// If Jasa company: hide Resto and Retail/Fashion specific modules
	if isJasaCompany {
		if strings.Contains(p, "type=resto") || strings.Contains(p, "type=retail") || strings.Contains(p, "type=fashion") ||
			strings.Contains(p, "kitchen") || strings.Contains(p, "monitoring-tables") ||
			strings.Contains(p, "layout-tables") || strings.Contains(p, "manage-tables") {
			return false
		}
	}

	return true
}

func GetMe(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var user models.User
	if err := database.DB.Preload("Company").Preload("Role.Menus", func(db *gorm.DB) *gorm.DB {
		return db.Order("sort_order ASC")
	}).First(&user, userID).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
		return
	}

	category := "F&B (Resto/Cafe)"
	if user.Company != nil && user.Company.BusinessCategory != "" {
		category = user.Company.BusinessCategory
	}

	var filteredMenus []models.SidebarMenu
	for _, m := range user.Role.Menus {
		if user.Role.Name == "Super User" || shouldShowMenuForCategory(m.Path, m.IsHeader, m.Title, category) {
			filteredMenus = append(filteredMenus, m)
		}
	}
	user.Role.Menus = filteredMenus

	c.JSON(http.StatusOK, gin.H{
		"user": user,
	})
}
