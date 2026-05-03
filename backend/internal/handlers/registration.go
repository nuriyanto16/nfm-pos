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
)

type RegistrationRequest struct {
	FullName     string `json:"fullName" binding:"required"`
	Email        string `json:"email" binding:"required,email"`
	Phone        string `json:"phone" binding:"required"`
	BusinessName string `json:"businessName" binding:"required"`
	CaptchaID    string `json:"captcha_id" binding:"required"`
	CaptchaValue string `json:"captcha_value" binding:"required"`
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

	// Basic phone validation (must be numeric and 9-15 chars)
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
		FullName:     req.FullName,
		Email:        req.Email,
		Phone:        req.Phone,
		BusinessName: req.BusinessName,
		Status:       "Pending",
		CreatedAt:    time.Now(),
	}

	if err := database.DB.Create(&registration).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Gagal menyimpan pendaftaran"})
		return
	}

	// Send Telegram Notification
	go sendTelegramNotification(registration)

	c.JSON(http.StatusCreated, gin.H{"message": "Pendaftaran berhasil", "data": registration})
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
		log.Printf("Telegram config missing (TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID)")
		return
	}

	// If chatID doesn't start with a number and doesn't have @, assume it's a public channel/user
	// and needs @ (though numeric ID is strongly preferred for private chats)
	if _, err := fmt.Sscanf(chatID, "%d", new(int)); err != nil {
		if chatID[0] != '@' {
			chatID = "@" + chatID
		}
	}

	message := fmt.Sprintf("🚀 *Pendaftaran Trial NFM POS Baru!*\n\n"+
		"*Nama:* %s\n"+
		"*Bisnis:* %s\n"+
		"*Email:* %s\n"+
		"*WhatsApp:* %s\n\n"+
		"Silakan hubungi segera untuk aktivasi.",
		reg.FullName, reg.BusinessName, reg.Email, reg.Phone)

	url := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", token)
	payload := map[string]interface{}{
		"chat_id":    chatID,
		"text":       message,
		"parse_mode": "Markdown",
	}
	jsonPayload, _ := json.Marshal(payload)

	resp, err := http.Post(url, "application/json", bytes.NewBuffer(jsonPayload))
	if err != nil {
		log.Printf("Error sending Telegram: %v\n", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		var result map[string]interface{}
		json.NewDecoder(resp.Body).Decode(&result)
		errMsg := fmt.Sprintf("%v", result["error"])
		if strings.Contains(errMsg, "chat not found") {
			log.Printf("Telegram API Error: Chat ID '%s' tidak ditemukan. Pastikan TELEGRAM_CHAT_ID di .env adalah ID angka (bukan username bot) dan Anda sudah men-start bot tersebut.", chatID)
		} else {
			log.Printf("Telegram API Error: %v\n", result)
		}
	} else {
		log.Printf("Telegram notification sent successfully to %s", chatID)
	}
}
