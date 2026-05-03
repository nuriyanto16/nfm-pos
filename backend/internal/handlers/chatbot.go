package handlers

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"github.com/gin-gonic/gin"
)

func ChatbotProxy(c *gin.Context) {
	chatbotURL := os.Getenv("CHATBOT_URL")
	if chatbotURL == "" {
		chatbotURL = "http://localhost:5000"
	}

	// Proxy to /chat
	body, _ := io.ReadAll(c.Request.Body)
	req, err := http.NewRequest("POST", chatbotURL+"/chat", bytes.NewBuffer(body))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	req.Header.Set("Content-Type", "application/json")
	
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Chatbot service unavailable"})
		return
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	
	var result map[string]interface{}
	json.Unmarshal(respBody, &result)

	c.JSON(resp.StatusCode, result)
}

func GetChatbotToken(c *gin.Context) {
	chatbotURL := os.Getenv("CHATBOT_URL")
	if chatbotURL == "" {
		chatbotURL = "http://localhost:5000"
	}

	resp, err := http.Get(chatbotURL + "/api/chat-token")
	if err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Chatbot service unavailable"})
		return
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	var result map[string]interface{}
	json.Unmarshal(respBody, &result)

	c.JSON(resp.StatusCode, result)
}
