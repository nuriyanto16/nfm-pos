package main

import (
	"fmt"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"
	"github.com/joho/godotenv"
)

func CheckDB() {
	godotenv.Load()
	database.ConnectDB()

	// Check Order
	hasOrder := database.DB.Migrator().HasTable(&models.Order{})
	fmt.Printf("Table orders exists: %v\n", hasOrder)
	hasCol := database.DB.Migrator().HasColumn(&models.Order{}, "service_charge_amount")
	fmt.Printf("Column service_charge_amount in orders exists: %v\n", hasCol)

	// Check OrderItem
	hasOrderItem := database.DB.Migrator().HasTable(&models.OrderItem{})
	fmt.Printf("Table order_items exists: %v\n", hasOrderItem)
	hasItemNotes := database.DB.Migrator().HasColumn(&models.OrderItem{}, "notes")
	fmt.Printf("Column notes in order_items exists: %v\n", hasItemNotes)
}
