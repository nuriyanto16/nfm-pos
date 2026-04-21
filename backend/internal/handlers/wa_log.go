package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"
	"strconv"

	"github.com/gin-gonic/gin"
)

// GetWALogs returns a paginated list of WhatsApp logs
func GetWALogs(c *gin.Context) {
	var logs []models.WALog
	var total int64

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "15"))
	offset := (page - 1) * limit

	query := database.DB.Model(&models.WALog{}).Scopes(middleware.GetQueryScope(c))

	query.Count(&total)
	query.Order("created_at desc").Limit(limit).Offset(offset).Find(&logs)

	c.JSON(http.StatusOK, gin.H{
		"data":         logs,
		"total_rows":   total,
		"current_page": page,
		"total_pages":  (total + int64(limit) - 1) / int64(limit),
	})
}
