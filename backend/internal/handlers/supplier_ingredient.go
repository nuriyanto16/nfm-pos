package handlers

import (
	"net/http"
	"strconv"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

// ─── Supplier ─────────────────────────────────────────────────────────────────

func GetSuppliers(c *gin.Context) {
	var suppliers []models.Supplier
	db := database.DB.Scopes(middleware.GetQueryScope(c))

	pagination, err := Paginate(c, db.Order("name"), &suppliers)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch suppliers"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func CreateSupplier(c *gin.Context) {
	var supplier models.Supplier
	if err := c.ShouldBindJSON(&supplier); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if companyID, exists := c.Get("companyID"); exists {
		supplier.CompanyID = companyID.(uint)
	}
	if err := database.DB.Create(&supplier).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create supplier"})
		return
	}
	c.JSON(http.StatusCreated, supplier)
}

func UpdateSupplier(c *gin.Context) {
	id := c.Param("id")
	var supplier models.Supplier
	if err := database.DB.First(&supplier, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Supplier not found"})
		return
	}

	var req models.Supplier
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.ID = supplier.ID
	req.CreatedAt = supplier.CreatedAt
	if err := database.DB.Save(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update supplier"})
		return
	}
	c.JSON(http.StatusOK, req)
}

func DeleteSupplier(c *gin.Context) {
	id := c.Param("id")
	var supplier models.Supplier
	if err := database.DB.First(&supplier, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Supplier not found"})
		return
	}
	if err := database.DB.Delete(&supplier).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete supplier"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Supplier deleted successfully"})
}

// ─── Ingredient ───────────────────────────────────────────────────────────────

func GetIngredients(c *gin.Context) {
	var ingredients []models.Ingredient
	db := database.DB.Scopes(middleware.GetQueryScope(c)).Preload("Supplier")

	pagination, err := Paginate(c, db.Order("name"), &ingredients)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch ingredients"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func CreateIngredient(c *gin.Context) {
	var ingredient models.Ingredient
	if err := c.ShouldBindJSON(&ingredient); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if companyID, exists := c.Get("companyID"); exists {
		ingredient.CompanyID = companyID.(uint)
	}
	if err := database.DB.Create(&ingredient).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create ingredient"})
		return
	}
	c.JSON(http.StatusCreated, ingredient)
}

func UpdateIngredient(c *gin.Context) {
	id := c.Param("id")
	var ingredient models.Ingredient
	if err := database.DB.First(&ingredient, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Ingredient not found"})
		return
	}
	var req models.Ingredient
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.ID = ingredient.ID
	req.CreatedAt = ingredient.CreatedAt
	if err := database.DB.Save(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update ingredient"})
		return
	}
	c.JSON(http.StatusOK, req)
}

func DeleteIngredient(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Delete(&models.Ingredient{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete ingredient"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Ingredient deleted successfully"})
}

// ─── Menu Ingredients (Recipe) ────────────────────────────────────────────────

func GetMenuIngredients(c *gin.Context) {
	menuID := c.Param("id")
	var recipes []models.MenuIngredient
	if err := database.DB.Preload("Ingredient").Where("menu_id = ?", menuID).Find(&recipes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch recipe"})
		return
	}
	c.JSON(http.StatusOK, recipes)
}

func SaveMenuIngredients(c *gin.Context) {
	menuID := c.Param("id")
	menuIDUint, _ := strconv.ParseUint(menuID, 10, 64)
	var recipes []models.MenuIngredient
	if err := c.ShouldBindJSON(&recipes); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Delete old recipe first, then insert new
	tx := database.DB.Begin()
	if err := tx.Where("menu_id = ?", menuID).Delete(&models.MenuIngredient{}).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update recipe"})
		return
	}

	for i := range recipes {
		recipes[i].ID = 0
		recipes[i].MenuID = uint(menuIDUint)
	}

	if len(recipes) > 0 {
		if err := tx.Create(&recipes).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save recipe"})
			return
		}
	}
	tx.Commit()
	c.JSON(http.StatusOK, recipes)
}
