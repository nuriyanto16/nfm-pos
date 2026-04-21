package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"

	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load("../../.env")
	if err != nil {
		godotenv.Load(".env")
	}

	database.ConnectDB()

	var menus []models.Menu
	if err := database.DB.Find(&menus).Error; err != nil {
		log.Fatal(err)
	}

	uploadsDir := "../../uploads"
	os.MkdirAll(uploadsDir, 0755)

	count := 0
	for _, menu := range menus {
		fileName := fmt.Sprintf("menu_%d.png", menu.ID)
		filePath := filepath.Join(uploadsDir, fileName)

		encodedName := url.QueryEscape(strings.ReplaceAll(menu.Name, " ", "\n"))
		imgURL := fmt.Sprintf("https://placehold.co/400x300/white/FF6B6B.png?text=%s", encodedName)

		log.Printf("Downloading image for %s -> %s", menu.Name, imgURL)
		
		resp, err := http.Get(imgURL)
		if err != nil {
			log.Printf("Failed to download image: %v", err)
			continue
		}
		
		out, err := os.Create(filePath)
		if err != nil {
			resp.Body.Close()
			log.Printf("Failed to create file: %v", err)
			continue
		}
		io.Copy(out, resp.Body)
		out.Close()
		resp.Body.Close()

		serverURL := "http://localhost:8080/uploads/" + fileName
		database.DB.Model(&menu).Update("image_url", serverURL)
		count++
	}
	
	log.Printf("Seeding complete. %d menus updated.", count)
}
