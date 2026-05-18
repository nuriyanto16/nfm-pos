package main

import (
	"fmt"
	"log"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load("../.env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	database.ConnectDB()

	var menus []models.SidebarMenu
	database.DB.Find(&menus)

	fmt.Println("--- SIDEBAR MENUS ---")
	for _, m := range menus {
		fmt.Printf("ID: %d | Title: %s | Path: %s\n", m.ID, m.Title, m.Path)
	}

	var adminRole models.Role
	database.DB.Preload("Menus").Where("name = ?", "Admin").First(&adminRole)
	fmt.Println("\n--- ADMIN ROLE MENUS ---")
	for _, m := range adminRole.Menus {
		fmt.Printf("ID: %d | Title: %s\n", m.ID, m.Title)
	}
}
