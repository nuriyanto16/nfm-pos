package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type RegistrationRequest struct {
	FullName         string `json:"fullName" binding:"required"`
	Email            string `json:"email" binding:"required,email"`
	Phone            string `json:"phone" binding:"required"`
	BusinessName     string `json:"businessName" binding:"required"`
	BusinessAddress  string `json:"businessAddress"`
	BusinessCategory string `json:"businessCategory"`
	CaptchaID        string `json:"captcha_id" binding:"required"`
	CaptchaValue     string `json:"captcha_value" binding:"required"`
}

func CreateRegistration(c *gin.Context) {
	var req RegistrationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Semua field wajib diisi dengan benar."})
		return
	}

	// Verify Captcha
	if !VerifyCaptcha(req.CaptchaID, req.CaptchaValue) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Kode captcha salah atau sudah kadaluarsa. Silakan refresh captcha."})
		return
	}

	// Basic phone validation
	digitsOnly := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, req.Phone)
	if len(digitsOnly) < 9 || len(digitsOnly) > 15 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Nomor telepon tidak valid (9-15 digit angka)."})
		return
	}

	registration := models.TrialRegistration{
		FullName:         req.FullName,
		Email:            req.Email,
		Phone:            req.Phone,
		BusinessName:     req.BusinessName,
		BusinessAddress:  req.BusinessAddress,
		BusinessCategory: req.BusinessCategory,
		Status:           "Pending",
		CreatedAt:        time.Now(),
	}

	if err := database.DB.Create(&registration).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan pendaftaran"})
		return
	}

	// Send Telegram Notification
	go sendTelegramNotification(registration)

	c.JSON(http.StatusCreated, gin.H{"message": "Pendaftaran berhasil", "data": registration})
}

func ApproveRegistration(c *gin.Context) {
	id := c.Param("id")

	// Security check for bot/internal
	botToken := c.GetHeader("X-Bot-Token")
	if botToken != os.Getenv("CHAT_SECRET") && os.Getenv("CHAT_SECRET") != "" {
		if _, exists := c.Get("userID"); !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			return
		}
	}

	var reg models.TrialRegistration
	if err := database.DB.First(&reg, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pendaftaran tidak ditemukan"})
		return
	}

	if reg.Status == "Approved" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Pendaftaran sudah disetujui sebelumnya"})
		return
	}

	tx := database.DB.Begin()
	if tx.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal memulai transaksi database"})
		return
	}

	// 1. Create Company
	companyCode := strings.ToUpper(strings.ReplaceAll(reg.BusinessName, " ", ""))
	if len(companyCode) > 10 {
		companyCode = companyCode[:10]
	}
	companyCode = fmt.Sprintf("%s%d", companyCode, reg.ID)

	company := models.Company{
		Name:      reg.BusinessName,
		Code:      companyCode,
		Address:   reg.BusinessAddress,
		Email:     reg.Email,
		Phone:     reg.Phone,
		IsActive:  true,
		CreatedAt: time.Now(),
	}
	if err := tx.Create(&company).Error; err != nil {
		tx.Rollback()
		log.Printf("Error creating company: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat Company: " + err.Error()})
		return
	}

	// 2. Create Branch
	branch := models.Branch{
		CompanyID: company.ID,
		Name:      "Pusat (HQ)",
		Code:      company.Code + "-01",
		Address:   reg.BusinessAddress,
		IsActive:  true,
		CreatedAt: time.Now(),
	}
	if err := tx.Create(&branch).Error; err != nil {
		tx.Rollback()
		log.Printf("Error creating branch: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat Branch: " + err.Error()})
		return
	}

	// 3. Create Admin User
	username := strings.ToLower(strings.Split(reg.Email, "@")[0])
	if username == "" {
		username = reg.Phone
	}
	// Check if username exists using transaction
	var count int64
	tx.Model(&models.User{}).Where("username = ?", username).Count(&count)
	if count > 0 {
		username = fmt.Sprintf("%s%d", username, reg.ID)
	}

	password := "nfm12345" // Default password
	hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)

	user := models.User{
		CompanyID:    company.ID,
		BranchID:     &branch.ID,
		FullName:     reg.FullName,
		Username:     username,
		PasswordHash: string(hash),
		RoleID:       1, // Admin
		IsActive:     true,
		CreatedAt:    time.Now(),
	}
	if err := tx.Create(&user).Error; err != nil {
		tx.Rollback()
		log.Printf("Error creating user: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat User: " + err.Error()})
		return
	}

	// 4. Update Registration Status
	if err := tx.Model(&reg).Update("status", "Approved").Error; err != nil {
		tx.Rollback()
		log.Printf("Error updating registration: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update pendaftaran"})
		return
	}

	// 5. Seed Basic Data
	cat := models.Category{CompanyID: company.ID, Name: "Makanan", Description: "Kategori Utama"}
	if err := tx.Create(&cat).Error; err != nil {
		tx.Rollback()
		log.Printf("Error creating category: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat kategori contoh"})
		return
	}
	
	menu := models.Menu{
		CompanyID:   company.ID,
		CategoryID:  cat.ID,
		Name:        "Contoh Produk",
		Price:       15000,
		IsAvailable: true,
		CreatedAt:   time.Now(),
	}
	if err := tx.Create(&menu).Error; err != nil {
		tx.Rollback()
		log.Printf("Error creating menu: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat menu contoh"})
		return
	}

	if err := tx.Commit().Error; err != nil {
		log.Printf("Error committing transaction: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan perubahan ke database"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":  "Pendaftaran berhasil disetujui",
		"company":  company.Name,
		"username": username,
		"password": password,
		"url":      "https://product.nfmtech.my.id",
	})
}

func GetRegistrations(c *gin.Context) {
	var registrations []models.TrialRegistration
	if err := database.DB.Order("created_at desc").Find(&registrations).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal mengambil data"})
		return
	}
	c.JSON(http.StatusOK, registrations)
}

func UpdateRegistrationStatus(c *gin.Context) {
	id := c.Param("id")
	var input struct {
		Status string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Model(&models.TrialRegistration{}).Where("id = ?", id).Update("status", input.Status).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Status berhasil diupdate"})
}

func DeleteRegistration(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Delete(&models.TrialRegistration{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menghapus data"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Data berhasil dihapus"})
}

func sendTelegramNotification(reg models.TrialRegistration) {
	token := os.Getenv("TELEGRAM_BOT_TOKEN")
	chatID := os.Getenv("TELEGRAM_CHAT_ID")
	if token == "" || chatID == "" {
		log.Printf("Telegram config missing")
		return
	}

	if _, err := fmt.Sscanf(chatID, "%d", new(int)); err != nil {
		if chatID[0] != '@' {
			chatID = "@" + chatID
		}
	}

	message := fmt.Sprintf("🚀 *Pendaftaran Trial Baru (Free UMKM)*\n\n"+
		"━━━━━━━━━━━━━━━━━━━━\n"+
		"👤 *Nama:* %s\n"+
		"🏢 *Bisnis:* %s\n"+
		"📁 *Kategori:* %s\n"+
		"📍 *Alamat:* %s\n"+
		"📧 *Email:* %s\n"+
		"📞 *WhatsApp:* `%s`\n"+
		"━━━━━━━━━━━━━━━━━━━━\n\n"+
		"💡 *Gunakan tombol di bawah untuk menyetujui dan membuat akun dummy otomatis.*",
		reg.FullName, reg.BusinessName, reg.BusinessCategory, reg.BusinessAddress, reg.Email, reg.Phone)

	url := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", token)
	
	payload := map[string]interface{}{
		"chat_id":    chatID,
		"text":       message,
		"parse_mode": "Markdown",
		"reply_markup": map[string]interface{}{
			"inline_keyboard": [][]map[string]interface{}{
				{
					{"text": "✅ Setujui & Buat Akun", "callback_data": fmt.Sprintf("approve_reg:%d", reg.ID)},
					{"text": "❌ Tolak", "callback_data": fmt.Sprintf("reject_reg:%d", reg.ID)},
				},
			},
		},
	}
	jsonPayload, _ := json.Marshal(payload)

	http.Post(url, "application/json", bytes.NewBuffer(jsonPayload))
}
