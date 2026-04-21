package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetSettings(c *gin.Context) {
	var settings []models.SystemSetting
	branchID, _ := c.Get("branchID")
	
	database.DB.Where("branch_id = ? OR branch_id IS NULL", branchID).Find(&settings)

	// Convert to map for easier frontend consumption
	settingsMap := make(map[string]string)
	for _, s := range settings {
		settingsMap[s.Key] = s.Value
	}

	c.JSON(http.StatusOK, settingsMap)
}

func UpdateSettings(c *gin.Context) {
	var req map[string]string
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	branchIDVal, _ := c.Get("branchID")
	branchID := branchIDVal.(uint)

	for key, value := range req {
		var setting models.SystemSetting
		err := database.DB.Where("branch_id = ? AND key = ?", branchID, key).First(&setting).Error
		
		if err != nil {
			// Create new
			setting = models.SystemSetting{
				BranchID: &branchID,
				Key:      key,
				Value:    value,
			}
			database.DB.Create(&setting)
		} else {
			// Update existing
			database.DB.Model(&setting).Update("value", value)
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Settings updated successfully"})
}
