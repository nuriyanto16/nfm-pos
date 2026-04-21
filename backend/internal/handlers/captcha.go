package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/mojocn/base64Captcha"
)

// Store captcha in memory by default
var store = base64Captcha.DefaultMemStore

func GenerateCaptcha(c *gin.Context) {
	// Generate captcha
	// Using digit for simplicity
	driver := base64Captcha.NewDriverDigit(80, 240, 5, 0.7, 80)
	cp := base64Captcha.NewCaptcha(driver, store)
	id, b64s, _, err := cp.Generate()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate captcha"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"captcha_id":   id,
		"captcha_image": b64s,
	})
}

func VerifyCaptcha(id, value string) bool {
	return store.Verify(id, value, true)
}
