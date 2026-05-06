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
		&models.SidebarMenu{},
		&models.BranchOrder{},
		&models.BranchOrderItem{},
		&models.GoodsReceipt{},
		&models.GoodsReceiptItem{},
		&models.GoodsIssue{},
		&models.GoodsIssueItem{},
		&models.TrialRegistration{},
	}

	for _, model := range modelsToMigrate {
		if err := DB.AutoMigrate(model); err != nil {
			log.Printf("Warning: failed to migrate %T: %v", model, err)
		}
	}

	SeedAccounts()
	SeedSidebarMenus()

	// Update orders status check constraint to include 'Siap'
	DB.Exec(`ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;`)
	DB.Exec(`ALTER TABLE orders ADD CONSTRAINT orders_status_check CHECK (status IN ('Pending', 'Proses', 'Siap', 'Selesai', 'Batal'));`)

	// Data fix for existing journal items (backfill company/branch from parent)
	DB.Exec(`UPDATE journal_items SET company_id = journal_entries.company_id, branch_id = journal_entries.branch_id 
			 FROM journal_entries WHERE journal_items.journal_id = journal_entries.id AND (journal_items.company_id = 0 OR journal_items.company_id IS NULL);`)

	SyncSequences()
}

func SyncSequences() {
	log.Println("Syncing database sequences...")
	tables := []string{
		"roles", "branches", "users", "customers", "categories", "menus",
		"ingredients", "suppliers", "promos", "tables", "orders", "payments",
		"system_settings", "accounts", "journal_entries", "journal_items",
		"stock_histories", "sidebar_menus", "trial_registrations",
	}

	for _, table := range tables {
		query := fmt.Sprintf("SELECT setval(pg_get_serial_sequence('%s', 'id'), COALESCE(MAX(id), 1)) FROM %s;", table, table)
		if err := DB.Exec(query).Error; err != nil {
			log.Printf("Warning: failed to sync sequence for %s: %v", table, err)
		}
	}
}

func SeedSidebarMenus() {
	var count int64
	DB.Model(&models.SidebarMenu{}).Count(&count)
	
	if count == 0 {
		log.Println("Seeding default sidebar menus...")
		// 1. Dashboard
		dashboard := models.SidebarMenu{Title: "Dashboard", Path: "/dashboard", Icon: "dashboard", SortOrder: 1}
		DB.Create(&dashboard)

		// 2. Headings
		operational := models.SidebarMenu{Title: "OPERASIONAL", IsHeader: true, SortOrder: 2}
		DB.Create(&operational)

		DB.Create(&models.SidebarMenu{Title: "Point of Sale", Path: "/pos", Icon: "shopping_cart", SortOrder: 3})
		DB.Create(&models.SidebarMenu{Title: "Kitchen Display", Path: "/kitchen", Icon: "kitchen", SortOrder: 4})
		DB.Create(&models.SidebarMenu{Title: "Daftar Pesanan", Path: "/orders", Icon: "receipt_long", SortOrder: 5})

		finance := models.SidebarMenu{Title: "KEUANGAN", IsHeader: true, SortOrder: 10}
		DB.Create(&finance)
		DB.Create(&models.SidebarMenu{Title: "Jurnal Umum", Path: "/finance/journal", Icon: "book", SortOrder: 11})
		DB.Create(&models.SidebarMenu{Title: "Buku Besar", Path: "/finance/ledger", Icon: "account_balance", SortOrder: 12})
		DB.Create(&models.SidebarMenu{Title: "Chart of Accounts", Path: "/finance/coa", Icon: "list_alt", SortOrder: 13})

		master := models.SidebarMenu{Title: "MASTER DATA", IsHeader: true, SortOrder: 20}
		DB.Create(&master)
		DB.Create(&models.SidebarMenu{Title: "Manajemen Menu", Path: "/menus", Icon: "restaurant_menu", SortOrder: 21})
		DB.Create(&models.SidebarMenu{Title: "Kategori", Path: "/menus", Icon: "category", SortOrder: 22})
		DB.Create(&models.SidebarMenu{Title: "Meja", Path: "/manage-tables", Icon: "table_restaurant", SortOrder: 23})
		DB.Create(&models.SidebarMenu{Title: "Pelanggan", Path: "/customers", Icon: "person", SortOrder: 24})
		DB.Create(&models.SidebarMenu{Title: "Stok & Bahan", Path: "/ingredients", Icon: "inventory_2", SortOrder: 25})

		system := models.SidebarMenu{Title: "SISTEM", IsHeader: true, SortOrder: 40}
		DB.Create(&system)
		DB.Create(&models.SidebarMenu{Title: "Pengaturan", Path: "/settings", Icon: "settings", SortOrder: 41})
		DB.Create(&models.SidebarMenu{Title: "User Management", Path: "/users", Icon: "people", SortOrder: 42})
		DB.Create(&models.SidebarMenu{Title: "Role Privilege", Path: "/roles", Icon: "security", SortOrder: 43})
		DB.Create(&models.SidebarMenu{Title: "Sidebar Management", Path: "/management/sidebar", Icon: "menu_open", SortOrder: 44})
		DB.Create(&models.SidebarMenu{Title: "Registrasi Trial", Path: "/registrations", Icon: "app_registration", SortOrder: 45})
	}

	// Ensure new menus exist
	newMenus := []models.SidebarMenu{
		{Title: "Monitoring Meja", Path: "/monitoring-tables", Icon: "monitor", SortOrder: 26},
		{Title: "Denah Meja", Path: "/layout-tables", Icon: "map", SortOrder: 27},
		{Title: "Pesanan Cabang", Path: "/inventory/branch-orders", Icon: "local_shipping", SortOrder: 62},
		{Title: "Laporan Penjualan", Path: "/reports/sales", Icon: "assessment", SortOrder: 63},
		{Title: "Monitoring Stok", Path: "/inventory/stock-history", Icon: "history", SortOrder: 64},
		{Title: "Registrasi Trial", Path: "/registrations", Icon: "app_registration", SortOrder: 45},
	}

	for _, nm := range newMenus {
		var existing models.SidebarMenu
		if err := DB.Where("path = ?", nm.Path).First(&existing).Error; err != nil {
			DB.Create(&nm)
		}
	}

	// Always assign all menus to Admin role (including any new ones added via UI)
	var allMenus []models.SidebarMenu
	DB.Find(&allMenus)
	var adminRole models.Role
	if err := DB.Where("name = ?", "Admin").First(&adminRole).Error; err != nil {
		adminRole = models.Role{Name: "Admin", Description: "Administrator with full access"}
		DB.Create(&adminRole)
	}
	DB.Model(&adminRole).Association("Menus").Replace(allMenus)
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
