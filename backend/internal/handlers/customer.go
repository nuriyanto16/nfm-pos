package handlers

import (
	"net/http"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetCustomers(c *gin.Context) {
	var customers []models.Customer
	db := database.DB.Model(&models.Customer{}).Scopes(middleware.GetQueryScope(c))

	if search := c.Query("search"); search != "" {
		db = db.Where("name ILIKE ? OR phone ILIKE ? OR email ILIKE ?", "%"+search+"%", "%"+search+"%", "%"+search+"%")
	}

	pagination, err := Paginate(c, db.Order("name"), &customers)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch customers"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func GetCustomerByID(c *gin.Context) {
	id := c.Param("id")
	var customer models.Customer
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).First(&customer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Customer not found"})
		return
	}
	c.JSON(http.StatusOK, customer)
}

func CreateCustomer(c *gin.Context) {
	var customer models.Customer
	if err := c.ShouldBindJSON(&customer); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if companyID, exists := c.Get("companyID"); exists {
		customer.CompanyID = companyID.(uint)
	}
	if err := database.DB.Create(&customer).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create customer"})
		return
	}
	c.JSON(http.StatusCreated, customer)
}

func UpdateCustomer(c *gin.Context) {
	id := c.Param("id")
	var customer models.Customer
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).First(&customer, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Customer not found"})
		return
	}
	var req models.Customer
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Explicitly update only the fields that are meant to be editable via this form
	// This prevents nuking system-managed fields like Tier and TotalSpent
	updateData := map[string]interface{}{
		"name":       req.Name,
		"phone":      req.Phone,
		"email":      req.Email,
		"address":    req.Address,
		"is_send_wa": req.IsSendWA,
	}

	if err := database.DB.Model(&customer).Updates(updateData).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update customer"})
		return
	}
	
	// Reload for response
	database.DB.Scopes(middleware.GetQueryScope(c)).First(&customer, customer.ID)
	c.JSON(http.StatusOK, customer)
}

func DeleteCustomer(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Delete(&models.Customer{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete customer"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Customer deleted successfully"})
}
