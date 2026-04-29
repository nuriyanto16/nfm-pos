package middleware

import (
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			return
		}

		tokenString := strings.Split(authHeader, "Bearer ")
		if len(tokenString) != 2 {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
			return
		}

		token, err := jwt.Parse(tokenString[1], func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method")
			}
			return []byte(os.Getenv("JWT_SECRET")), nil
		})

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			return
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			if userID, ok := claims["user_id"].(float64); ok {
				c.Set("userID", uint(userID))
			}
			c.Set("role", claims["role"])
			if branchID, exists := claims["branch_id"]; exists && branchID != nil {
				c.Set("branchID", uint(branchID.(float64)))
			}
			if companyID, exists := claims["company_id"]; exists && companyID != nil {
				c.Set("companyID", uint(companyID.(float64)))
			}
		}

		c.Next()
	}
}

// GetQueryScope returns a GORM scope that filters by branch_id if the user is not an admin
func GetQueryScope(c *gin.Context) func(tx *gorm.DB) *gorm.DB {
	role := c.GetString("role")
	branchID, branchExists := c.Get("branchID")
	companyID, companyExists := c.Get("companyID")

	return func(tx *gorm.DB) *gorm.DB {
		// Filter by company first (multi-tenancy)
		if companyExists && companyID != nil {
			tx = tx.Where("company_id = ?", companyID)
		}

		// Executive and Admin can see everything within company (all branches)
		if role == "Executive" || role == "Admin" {
			return tx
		}

		// Others are scoped to their branch, allowing NULL branch_id (global items)
		if branchExists && branchID != nil {
			return tx.Where("(branch_id = ? OR branch_id IS NULL)", branchID)
		}

		return tx
	}
}

func CORSMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
