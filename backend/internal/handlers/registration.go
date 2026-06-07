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
	"pos-resto/backend/internal/services"
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
	Plan             string `json:"plan"`
	POSType          string `json:"pos_type"`
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

	// Default to UMKM if empty
	planVal := req.Plan
	if planVal == "" {
		planVal = "UMKM"
	}

	posTypeVal := req.POSType
	if posTypeVal == "" {
		posTypeVal = "resto"
		bc := strings.ToLower(req.BusinessCategory)
		if strings.Contains(bc, "retail") || strings.Contains(bc, "toko") {
			posTypeVal = "retail"
		} else if strings.Contains(bc, "jasa") || strings.Contains(bc, "laundry") || strings.Contains(bc, "salon") || strings.Contains(bc, "cuci") {
			posTypeVal = "jasa"
		} else if strings.Contains(bc, "fashion") {
			posTypeVal = "fashion"
		}
	}

	isPaidVal := false
	if planVal == "UMKM" {
		isPaidVal = true
	}

	registration := models.TrialRegistration{
		FullName:         req.FullName,
		Email:            req.Email,
		Phone:            req.Phone,
		BusinessName:     req.BusinessName,
		BusinessAddress:  req.BusinessAddress,
		BusinessCategory: req.BusinessCategory,
		Status:           "Pending",
		Plan:             planVal,
		POSType:          posTypeVal,
		IsPaid:           isPaidVal,
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

	posType := "resto"
	if reg.POSType != "" {
		posType = reg.POSType
	} else {
		bc := strings.ToLower(reg.BusinessCategory)
		if strings.Contains(bc, "retail") || strings.Contains(bc, "toko") {
			posType = "retail"
		} else if strings.Contains(bc, "jasa") || strings.Contains(bc, "laundry") || strings.Contains(bc, "salon") || strings.Contains(bc, "cuci") {
			posType = "jasa"
		} else if strings.Contains(bc, "fashion") {
			posType = "fashion"
		}
	}

	// 1. Create Company
	companyCode := strings.ToUpper(strings.ReplaceAll(reg.BusinessName, " ", ""))
	if len(companyCode) > 10 {
		companyCode = companyCode[:10]
	}
	companyCode = fmt.Sprintf("%s%d", companyCode, reg.ID)

	company := models.Company{
		Name:             reg.BusinessName,
		Code:             companyCode,
		Address:          reg.BusinessAddress,
		Email:            reg.Email,
		Phone:            reg.Phone,
		IsActive:         true,
		SubscriptionPlan: reg.Plan,
		BusinessCategory: reg.BusinessCategory,
		POSType:          posType,
		CreatedAt:        time.Now(),
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
		OpenTime:  "08:00:00",
		CloseTime: "22:00:00",
		IsActive:  true,
		POSType:   posType,
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

	// Find Admin role ID dynamically instead of hardcoding '1' to avoid foreign key violations
	var adminRole models.Role
	if err := tx.Where("name = ?", "Admin").First(&adminRole).Error; err != nil {
		tx.Rollback()
		log.Printf("Error finding Admin role: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menemukan Role Admin di database"})
		return
	}

	user := models.User{
		CompanyID:    company.ID,
		BranchID:     &branch.ID,
		FullName:     reg.FullName,
		Username:     username,
		PasswordHash: string(hash),
		RoleID:       adminRole.ID,
		IsActive:     true,
		CreatedAt:    time.Now(),
	}
	if err := tx.Create(&user).Error; err != nil {
		tx.Rollback()
		log.Printf("Error creating user: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal membuat User: " + err.Error()})
		return
	}

	// 4. Update Registration Status & Payment Status
	if err := tx.Model(&reg).Updates(map[string]interface{}{
		"status":  "Approved",
		"is_paid": true,
	}).Error; err != nil {
		tx.Rollback()
		log.Printf("Error updating registration: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update pendaftaran"})
		return
	}

	if err := tx.Commit().Error; err != nil {
		log.Printf("Error committing transaction: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan pendaftaran ke database: " + err.Error()})
		return
	}

	// 5. Seed Basic Data (Optional - Outside main transaction)
	// We do this AFTER commit so it doesn't break the main account creation
	go seedSampleData(company.ID, reg.BusinessCategory)

	// 6. Send WA Notification to user
	go services.SendApprovalToWA(reg, username, password)

	c.JSON(http.StatusOK, gin.H{
		"message":  "Pendaftaran berhasil disetujui",
		"company":  company.Name,
		"username": username,
		"password": password,
		"url":      "https://product.nfmtech.my.id",
	})
}

// helper to seed sample data using global DB
func seedSampleData(companyID uint, businessCategory string) {
	posType := "resto"
	catName := "Makanan"
	prodName := "Contoh Produk Makanan"
	
	bc := strings.ToLower(businessCategory)
	if strings.Contains(bc, "retail") || strings.Contains(bc, "toko") {
		posType = "retail"
		catName = "Barang Retail"
		prodName = "Contoh Barang Retail"
	} else if strings.Contains(bc, "jasa") || strings.Contains(bc, "laundry") || strings.Contains(bc, "salon") || strings.Contains(bc, "cuci") {
		posType = "jasa"
		catName = "Layanan Jasa"
		prodName = "Contoh Layanan Jasa"
	} else if strings.Contains(bc, "fashion") {
		posType = "fashion"
		catName = "Fashion"
		prodName = "Contoh Pakaian"
	}

	var cat models.Category
	err := database.DB.Where(models.Category{CompanyID: companyID, Name: catName, POSType: posType}).
		Assign(models.Category{Description: "Kategori Utama", POSType: posType}).
		FirstOrCreate(&cat).Error
	if err != nil {
		log.Printf("Warning: Failed to seed sample category: %v", err)
		return
	}

	menu := models.Menu{
		CompanyID:   companyID,
		CategoryID:  cat.ID,
		Name:        prodName,
		Price:       15000,
		IsAvailable: true,
		POSType:     posType,
		CreatedAt:   time.Now(),
	}
	if err := database.DB.Create(&menu).Error; err != nil {
		log.Printf("Warning: Failed to seed sample menu: %v", err)
	}
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
	var input map[string]interface{}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := make(map[string]interface{})
	if status, exists := input["status"]; exists {
		updates["status"] = status
	}
	if isPaid, exists := input["is_paid"]; exists {
		updates["is_paid"] = isPaid
	}
	if posType, exists := input["pos_type"]; exists {
		updates["pos_type"] = posType
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tidak ada data yang diupdate"})
		return
	}

	if err := database.DB.Model(&models.TrialRegistration{}).Where("id = ?", id).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal update status"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Status berhasil diupdate", "data": updates})
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

	paymentStatus := "🔴 Belum Bayar"
	if reg.IsPaid {
		paymentStatus = "🟢 Sudah Bayar (Free/Lunas)"
	}

	message := fmt.Sprintf("🚀 *Pendaftaran Baru (%s)*\n\n"+
		"━━━━━━━━━━━━━━━━━━━━\n"+
		"👤 *Nama:* %s\n"+
		"🏢 *Bisnis:* %s\n"+
		"📁 *Kategori:* %s\n"+
		"🖥️ *Jenis POS:* %s\n"+
		"💳 *Status Bayar:* %s\n"+
		"📍 *Alamat:* %s\n"+
		"📧 *Email:* %s\n"+
		"📞 *WhatsApp:* `%s`\n"+
		"━━━━━━━━━━━━━━━━━━━━\n\n"+
		"💡 *Gunakan tombol di bawah untuk menyetujui dan membuat akun dummy otomatis.*",
		reg.Plan, reg.FullName, reg.BusinessName, reg.BusinessCategory, reg.POSType, paymentStatus, reg.BusinessAddress, reg.Email, reg.Phone)

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
