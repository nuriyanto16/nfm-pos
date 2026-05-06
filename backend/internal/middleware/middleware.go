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
		// Try to determine the table name from the statement's model or schema
		tableName := ""
		if tx.Statement != nil {
			if tx.Statement.Table != "" {
				tableName = tx.Statement.Table
			} else if tx.Statement.Schema != nil {
				tableName = tx.Statement.Schema.Table
			} else if tx.Statement.Model != nil {
				if err := tx.Statement.Parse(tx.Statement.Model); err == nil && tx.Statement.Schema != nil {
					tableName = tx.Statement.Schema.Table
				}
			} else if tx.Statement.Dest != nil {
				// Try to parse from destination if model is not set
				if err := tx.Statement.Parse(tx.Statement.Dest); err == nil && tx.Statement.Schema != nil {
					tableName = tx.Statement.Schema.Table
				}
			}
		}

		// Filter by company first (multi-tenancy) - Mandatory for all
		if companyExists && companyID != nil {
			if tableName != "" {
				tx = tx.Where(fmt.Sprintf("%s.company_id = ?", tableName), companyID)
			} else {
				tx = tx.Where("company_id = ?", companyID)
			}
		}

		// Executive and Admin can see everything within their company (all branches)
		if strings.EqualFold(role, "Executive") || strings.EqualFold(role, "Admin") {
			return tx
		}

		// Others (Cashier, Kitchen, Manager) are strictly scoped to their branch
		if branchExists && branchID != nil {
			if tableName != "" {
				// Allow branch-specific data OR company-wide master data (branch_id IS NULL)
				return tx.Where(fmt.Sprintf("(%s.branch_id = ? OR %s.branch_id IS NULL)", tableName, tableName), branchID)
			}
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
