package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetSettings(c *gin.Context) {
	var settings []models.SystemSetting
	
	// Get branchID from context if exists
	branchIDVal, branchExists := c.Get("branchID")
	
	// We use the scope to filter by companyID and potentially branchID
	database.DB.Scopes(middleware.GetQueryScope(c)).Order("branch_id ASC").Find(&settings)

	// Convert to map for easier frontend consumption
	// Since we ordered by branch_id ASC, the entries with branch_id != NULL 
	// (which come after NULLs) will overwrite the global ones in the map.
	// This provides automatic "branch overrides global" logic.
	settingsMap := make(map[string]string)
	for _, s := range settings {
		// If branchExists and s.BranchID matches branchIDVal, it's a specific match.
		// If s.BranchID is nil, it's a global fallback.
		
		// If user has a branch, we ONLY want their branch settings OR global ones.
		// If user is Admin/Executive (no specific branch scope in middleware), 
		// they see global ones + branch ones (last branch wins).
		
		if branchExists && branchIDVal != nil {
			targetID := branchIDVal.(uint)
			if s.BranchID != nil && *s.BranchID != targetID {
				// Skip settings from other branches
				continue
			}
		}
		
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

	branchIDVal, exists := c.Get("branchID")
	var branchID *uint
	if exists && branchIDVal != nil {
		id := branchIDVal.(uint)
		branchID = &id
	}

	for key, value := range req {
		var setting models.SystemSetting
		query := database.DB.Where("key = ?", key)
		if branchID != nil {
			query = query.Where("branch_id = ?", *branchID)
		} else {
			query = query.Where("branch_id IS NULL")
		}

		err := query.First(&setting).Error
		
		if err != nil {
			// Create new
			setting = models.SystemSetting{
				BranchID: branchID,
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
