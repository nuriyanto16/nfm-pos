package handlers

import (
	"net/http"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
	"image"
	"image/jpeg"
	_ "image/png"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

func GetCompanies(c *gin.Context) {
	var companies []models.Company
	if err := database.DB.Find(&companies).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch companies"})
		return
	}
	c.JSON(http.StatusOK, companies)
}

func GetCompanyByID(c *gin.Context) {
	id := c.Param("id")
	var company models.Company
	if err := database.DB.First(&company, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Company not found"})
		return
	}
	c.JSON(http.StatusOK, company)
}

func CreateCompany(c *gin.Context) {
	var company models.Company
	if err := c.ShouldBindJSON(&company); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Company code must be unique
	if company.Code == "" {
		company.Code = uuid.New().String()[:8]
	}

	if err := database.DB.Create(&company).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create company"})
		return
	}
	c.JSON(http.StatusCreated, company)
}

func UploadCompanyLogo(c *gin.Context) {
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No image uploaded"})
		return
	}

	folder := filepath.Join("uploads", "logo")
	if _, err := os.Stat(folder); os.IsNotExist(err) {
		os.MkdirAll(folder, 0755)
	}

	ext := filepath.Ext(file.Filename)
	if ext == "" {
		ext = ".jpg"
	}
	filename := "logo-" + uuid.New().String()[:8] + ext
	filePath := filepath.Join(folder, filename)

	src, err := file.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open image"})
		return
	}
	defer src.Close()

	img, _, err := image.Decode(src)
	if err != nil {
		if err := c.SaveUploadedFile(file, filePath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
			return
		}
	} else {
		out, err := os.Create(filePath)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create destination file"})
			return
		}
		defer out.Close()
		jpeg.Encode(out, img, &jpeg.Options{Quality: 75})
	}

	urlPath := "/" + filepath.ToSlash(filePath)
	c.JSON(http.StatusOK, gin.H{"url": urlPath})
}

func UpdateCompany(c *gin.Context) {
	id := c.Param("id")
	var company models.Company
	if err := database.DB.First(&company, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Company not found"})
		return
	}
	var req models.Company
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.ID = company.ID
	if err := database.DB.Save(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update company"})
		return
	}
	c.JSON(http.StatusOK, req)
}

func DeleteCompany(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Delete(&models.Company{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete company"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Company deleted successfully"})
}
