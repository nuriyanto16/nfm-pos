package database

import (
	"fmt"
	"log"
	"os"

	"pos-resto/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDB() {
	host := os.Getenv("DB_HOST")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")
	port := os.Getenv("DB_PORT")

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Jakarta",
		host, user, password, dbname, port)

	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database. \n", err)
	}

	log.Println("Connected to Database")

	// Auto Migrate per model to be more robust
	modelsToMigrate := []interface{}{
		&models.Role{},
		&models.Branch{},
		&models.User{},
		&models.Customer{},
		&models.Category{},
		&models.Menu{},
		&models.Ingredient{},
		&models.MenuIngredient{},
		&models.Supplier{},
		&models.Promo{},
		&models.Table{},
		&models.Order{},
		&models.OrderItem{},
		&models.Payment{},
		&models.CashierSession{},
		&models.SystemSetting{},
		&models.Account{},
		&models.JournalEntry{},
		&models.JournalItem{},
		&models.StockHistory{},
		&models.WALog{},
	}

	for _, model := range modelsToMigrate {
		if err := DB.AutoMigrate(model); err != nil {
			log.Printf("Warning: failed to migrate %T: %v", model, err)
		}
	}

	SeedAccounts()
}

func SeedAccounts() {
	accounts := []models.Account{
		{Code: "1101", Name: "Kas", Type: "Asset"},
		{Code: "1201", Name: "Persediaan Bahan Baku", Type: "Asset"},
		{Code: "2101", Name: "Hutang PPN", Type: "Liability"},
		{Code: "3101", Name: "Modal Pemilik", Type: "Equity"},
		{Code: "4101", Name: "Pendapatan Penjualan", Type: "Revenue"},
		{Code: "4102", Name: "Pendapatan Service", Type: "Revenue"},
		{Code: "5101", Name: "Harga Pokok Penjualan", Type: "Expense"},
		{Code: "5201", Name: "Beban Operasional", Type: "Expense"},
	}

	for _, acc := range accounts {
		var existing models.Account
		if err := DB.Where("code = ?", acc.Code).First(&existing).Error; err != nil {
			DB.Create(&acc)
		}
	}
}
