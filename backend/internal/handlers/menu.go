package handlers

import (
	"net/http"
	"os"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"image"
	"image/jpeg"
	_ "image/png" // Register PNG decoder
	"path/filepath"
)

func GetMenus(c *gin.Context) {
	var menus []models.Menu
	db := database.DB.Model(&models.Menu{}).Scopes(middleware.GetQueryScope(c)).Preload("Category")

	if cat := c.Query("category_id"); cat != "" {
		db = db.Where("category_id = ?", cat)
	}
	if available := c.Query("available"); available == "true" {
		db = db.Where("is_available = true")
	}

	pagination, err := Paginate(c, db, &menus)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch menus"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func GetMenuByID(c *gin.Context) {
	id := c.Param("id")
	var menu models.Menu
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Preload("Category").First(&menu, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Menu not found"})
		return
	}
	c.JSON(http.StatusOK, menu)
}

func CreateMenu(c *gin.Context) {
	var menu models.Menu
	if err := c.ShouldBindJSON(&menu); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Automatically set CompanyID from context
	if companyID, exists := c.Get("companyID"); exists {
		menu.CompanyID = companyID.(uint)
	}
	
	if err := database.DB.Create(&menu).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create menu"})
		return
	}
	database.DB.Scopes(middleware.GetQueryScope(c)).Preload("Category").First(&menu, menu.ID)
	c.JSON(http.StatusCreated, menu)
}

func UpdateMenu(c *gin.Context) {
	id := c.Param("id")
	var menu models.Menu
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).First(&menu, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Menu not found"})
		return
	}
	var req models.Menu
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.ID = menu.ID
	req.CreatedAt = menu.CreatedAt
	if err := database.DB.Save(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update menu"})
		return
	}
	database.DB.Scopes(middleware.GetQueryScope(c)).Preload("Category").First(&req, req.ID)
	c.JSON(http.StatusOK, req)
}

func DeleteMenu(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Delete(&models.Menu{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete menu"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Menu deleted successfully"})
}

// ─── Category ─────────────────────────────────────────────────────────────────

func GetCategories(c *gin.Context) {
	var categories []models.Category
	db := database.DB.Model(&models.Category{}).Scopes(middleware.GetQueryScope(c))

	pagination, err := Paginate(c, db, &categories)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}

	c.JSON(http.StatusOK, pagination)
}

func CreateCategory(c *gin.Context) {
	var cat models.Category
	if err := c.ShouldBindJSON(&cat); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Automatically set CompanyID from context
	if companyID, exists := c.Get("companyID"); exists {
		cat.CompanyID = companyID.(uint)
	}

	if err := database.DB.Create(&cat).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create category"})
		return
	}
	c.JSON(http.StatusCreated, cat)
}

func UpdateCategory(c *gin.Context) {
	id := c.Param("id")
	var cat models.Category
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).First(&cat, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Category not found"})
		return
	}
	var req models.Category
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.ID = cat.ID
	if err := database.DB.Save(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update category"})
		return
	}
	c.JSON(http.StatusOK, req)
}

func DeleteCategory(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Scopes(middleware.GetQueryScope(c)).Delete(&models.Category{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete category"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Category deleted successfully"})
}

func UploadMenuImage(c *gin.Context) {
	handleImageUpload(c, "uploads/menu")
}

func UploadLogo(c *gin.Context) {
	handleImageUpload(c, "uploads/logo")
}

func handleImageUpload(c *gin.Context, folder string) {
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No image uploaded"})
		return
	}

	// Create directory if not exists
	if _, err := os.Stat(folder); os.IsNotExist(err) {
		os.MkdirAll(folder, 0755)
	}

	ext := filepath.Ext(file.Filename)
	if ext == "" {
		ext = ".jpg"
	}
	filename := uuid.New().String() + ext
	filePath := filepath.Join(folder, filename)

	// Open the uploaded file
	src, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open image"})
		return
	}
	defer src.Close()

	// Decode the image to normalize/compress if it's an image
	img, _, err := image.Decode(src)
	if err != nil {
		// Fallback to direct save if decoding fails
		if err := c.SaveUploadedFile(file, filePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
			return
		}
	} else {
		// Create the destination file
		// If it's a large image, we might want to re-encode it as JPEG
		out, err := os.Create(filePath)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create destination file"})
			return
		}
		defer out.Close()

		// Save with JPEG compression
		err = jpeg.Encode(out, img, &jpeg.Options{Quality: 70})
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to compress image"})
			return
		}
	}

	// Return web-friendly path (always use forward slash)
	urlPath := "/" + filepath.ToSlash(filePath)
	c.JSON(http.StatusOK, gin.H{"url": urlPath})
}
