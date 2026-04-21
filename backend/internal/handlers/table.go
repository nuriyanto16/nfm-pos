package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetTables(c *gin.Context) {
	var tables []models.Table
	db := database.DB.Model(&models.Table{}).Scopes(middleware.GetQueryScope(c))

	pagination, err := Paginate(c, db.Order("table_number"), &tables)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tables"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func CreateTable(c *gin.Context) {
	var table models.Table
	if err := c.ShouldBindJSON(&table); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Set branch from user if not provided
	branchID, _ := c.Get("branchID")
	if table.BranchID == 0 && branchID != nil {
		table.BranchID = branchID.(uint)
	}

	// Normalize status
	if table.Status == "" || table.Status == "Available" {
		table.Status = "Kosong"
	} else if table.Status == "Occupied" {
		table.Status = "Digunakan"
	}

	if err := database.DB.Create(&table).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create table"})
		return
	}
	c.JSON(http.StatusCreated, table)
}

func UpdateTable(c *gin.Context) {
	id := c.Param("id")
	var table models.Table
	if err := database.DB.First(&table, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Table not found"})
		return
	}

	if err := c.ShouldBindJSON(&table); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Normalize status
	if table.Status == "Available" {
		table.Status = "Kosong"
	} else if table.Status == "Occupied" {
		table.Status = "Digunakan"
	}

	if err := database.DB.Save(&table).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update table"})
		return
	}
	c.JSON(http.StatusOK, table)
}

func UpdateTableStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var table models.Table
	if err := database.DB.First(&table, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Table not found"})
		return
	}

	// Normalize status
	if req.Status == "Available" {
		req.Status = "Kosong"
	} else if req.Status == "Occupied" {
		req.Status = "Digunakan"
	}

	if err := database.DB.Model(&table).Update("status", req.Status).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update table status"})
		return
	}

	c.JSON(http.StatusOK, table)
}

func DeleteTable(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Delete(&models.Table{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete table"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Table deleted successfully"})
}
