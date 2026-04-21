package services

import (
	"fmt"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"
)

// SendReceiptToWA simulates sending a receipt via WhatsApp
func SendReceiptToWA(customer models.Customer, order models.Order) {
	fmt.Printf("[WA DEBUG] Checking customer %s (ID: %d), IsSendWA: %v, Phone: %s\n", customer.Name, customer.ID, customer.IsSendWA, customer.Phone)
	if !customer.IsSendWA {
		fmt.Printf("[WA DEBUG] Send WA is OFF for this customer. Skipping.\n")
		return
	}
	if customer.Phone == "" {
		fmt.Printf("[WA DEBUG] Customer phone is empty. Skipping.\n")
		return
	}

	// Get Sender Number from settings
	var senderSetting models.SystemSetting
	database.DB.Where("branch_id = ? AND key = ?", order.BranchID, "wa_sender_number").First(&senderSetting)
	senderNum := senderSetting.Value
	if senderNum == "" {
		senderNum = "Default (System)"
	}

	// Simulation of sending WA message
	message := fmt.Sprintf(
		"Halo *%s*,\n\nTerima kasih telah berkunjung ke *POS Resto*!\n\nBerikut ringkasan pesanan Anda:\n📌 No. Order: #%d\n💰 Total: Rp %.2f\n📅 Tanggal: %s\n\nStruk selengkapnya dapat Anda lihat di kasir. Sampai jumpa lagi!",
		customer.Name,
		order.ID,
		order.TotalAmount,
		order.CreatedAt.Format("02/01/2006 15:04"),
	)

	fmt.Printf("\n--- [SIMULASI WHATSAPP] ---\n📡 Pengirim: %s\n📲 Penerima: %s (%s)\n💬 Pesan:\n%s\n---------------------------\n", 
		senderNum, customer.Phone, customer.Name, message)

	// Save log to database
	waLog := models.WALog{
		BranchID:   order.BranchID,
		OrderID:    order.ID,
		CustomerID: &customer.ID,
		Phone:      customer.Phone,
		Message:    message,
		Status:     "Success", // Simulated as success
	}
	if err := database.DB.Create(&waLog).Error; err != nil {
		fmt.Printf("❌ Failed to create WA Log: %v\n", err)
	} else {
		fmt.Printf("✅ WA Log created successfully for Order #%d\n", order.ID)
	}
}
