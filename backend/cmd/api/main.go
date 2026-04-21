package main

import (
	"log"
	"os"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/handlers"
	"pos-resto/backend/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Println("No .env file found, relying on environment variables")
	}

	database.ConnectDB()

	r := gin.Default()

	// Fix: SetTrustedProxies(nil) to resolve proxy warning
	r.SetTrustedProxies(nil)

	// CORS Middleware
	r.Use(middleware.CORSMiddleware())

	// Routes
	r.Static("/uploads", "./uploads")
	api := r.Group("/api")

	// Public routes
	api.POST("/login", handlers.Login)
	api.GET("/captcha", handlers.GenerateCaptcha)

	// Protected routes
	protected := api.Group("/")
	protected.Use(middleware.AuthMiddleware())

	// ─── Users ────────────────────────────────────────────────────────────────
	protected.GET("/users", handlers.GetUsers)
	protected.POST("/users", handlers.CreateUser)
	protected.PUT("/users/:id", handlers.UpdateUser)
	protected.PUT("/users/:id/password", handlers.ChangeUserPassword)
	protected.DELETE("/users/:id", handlers.DeleteUser)

	// ─── Roles ────────────────────────────────────────────────────────────────
	protected.GET("/roles", handlers.GetRoles)
	protected.POST("/roles", handlers.CreateRole)
	protected.PUT("/roles/:id", handlers.UpdateRole)
	protected.DELETE("/roles/:id", handlers.DeleteRole)

	// ─── Menus ────────────────────────────────────────────────────────────────
	protected.GET("/menus", handlers.GetMenus)
	protected.GET("/menus/:id", handlers.GetMenuByID)
	protected.POST("/menus", handlers.CreateMenu)
	protected.PUT("/menus/:id", handlers.UpdateMenu)
	protected.DELETE("/menus/:id", handlers.DeleteMenu)
	protected.POST("/menus/upload", handlers.UploadMenuImage)

	// ─── Menu Ingredients (Recipe) ────────────────────────────────────────────
	protected.GET("/menus/:id/ingredients", handlers.GetMenuIngredients)
	protected.POST("/menus/:id/ingredients", handlers.SaveMenuIngredients)

	// ─── Categories ───────────────────────────────────────────────────────────
	protected.GET("/categories", handlers.GetCategories)
	protected.POST("/categories", handlers.CreateCategory)
	protected.PUT("/categories/:id", handlers.UpdateCategory)
	protected.DELETE("/categories/:id", handlers.DeleteCategory)

	// ─── Customers ────────────────────────────────────────────────────────────
	protected.GET("/customers", handlers.GetCustomers)
	protected.GET("/customers/:id", handlers.GetCustomerByID)
	protected.POST("/customers", handlers.CreateCustomer)
	protected.PUT("/customers/:id", handlers.UpdateCustomer)
	protected.DELETE("/customers/:id", handlers.DeleteCustomer)

	// ─── Dashboard ────────────────────────────────────────────────────────────
	protected.GET("/dashboard/stats", handlers.GetDashboardStats)

	// ─── Tables ───────────────────────────────────────────────────────────────
	protected.GET("/tables", handlers.GetTables)
	protected.POST("/tables", handlers.CreateTable)
	protected.PUT("/tables/:id", handlers.UpdateTable)
	protected.PUT("/tables/:id/status", handlers.UpdateTableStatus)
	protected.DELETE("/tables/:id", handlers.DeleteTable)

	// ─── Orders ───────────────────────────────────────────────────────────────
	protected.GET("/orders", handlers.GetOrders)
	protected.GET("/orders/:id", handlers.GetOrderByID)
	protected.POST("/orders", handlers.CreateOrder)
	protected.PUT("/orders/:id/status", handlers.UpdateOrderStatus)
	protected.POST("/orders/:id/void", handlers.VoidOrder)

	// ─── Payments ─────────────────────────────────────────────────────────────
	protected.POST("/orders/:id/pay", handlers.ProcessPayment)

	// ─── Profile ──────────────────────────────────────────────────────────────
	protected.GET("/profile", handlers.GetProfile)

	// ─── Promos ───────────────────────────────────────────────────────────────
	protected.GET("/promos", handlers.GetPromos)
	protected.GET("/promos/active", handlers.GetActivePromos)
	protected.POST("/promos", handlers.CreatePromo)
	protected.PUT("/promos/:id", handlers.UpdatePromo)
	protected.PUT("/promos/:id/toggle", handlers.TogglePromoStatus)
	protected.DELETE("/promos/:id", handlers.DeletePromo)

	// ─── Suppliers ────────────────────────────────────────────────────────────
	protected.GET("/suppliers", handlers.GetSuppliers)
	protected.POST("/suppliers", handlers.CreateSupplier)
	protected.PUT("/suppliers/:id", handlers.UpdateSupplier)
	protected.DELETE("/suppliers/:id", handlers.DeleteSupplier)

	// ─── Ingredients ──────────────────────────────────────────────────────────
	protected.GET("/ingredients", handlers.GetIngredients)
	protected.POST("/ingredients", handlers.CreateIngredient)
	protected.PUT("/ingredients/:id", handlers.UpdateIngredient)
	protected.DELETE("/ingredients/:id", handlers.DeleteIngredient)

	// ─── Cashier Sessions ─────────────────────────────────────────────────────
	protected.GET("/sessions", handlers.GetCashierSessions)
	protected.GET("/sessions/active", handlers.GetActiveCashierSession)
	protected.GET("/sessions/active/summary", handlers.GetActiveCashierSessionSummary)
	protected.POST("/sessions/open", handlers.OpenCashierSession)
	protected.PUT("/sessions/:id/close", handlers.CloseCashierSession)

	// ─── Branches ─────────────────────────────────────────────────────────────
	protected.GET("/branches", handlers.GetBranches)
	protected.GET("/branches/:id", handlers.GetBranchByID)
	protected.POST("/branches", handlers.CreateBranch)
	protected.PUT("/branches/:id", handlers.UpdateBranch)
	protected.DELETE("/branches/:id", handlers.DeleteBranch)

	protected.GET("/reports/financial", handlers.GetFinancialReport)
	protected.GET("/reports/financial/export", handlers.ExportFinancialCSV)
	protected.GET("/reports/ingredients", handlers.GetIngredientConsumptionReport)

	// ─── Settings ─────────────────────────────────────────────────────────────
	protected.GET("/settings", handlers.GetSettings)
	protected.POST("/settings", handlers.UpdateSettings)

	// ─── Finance ──────────────────────────────────────────────────────────────
	protected.GET("/finance/coa", handlers.GetCOA)
	protected.POST("/finance/coa", handlers.CreateAccount)
	protected.PUT("/finance/coa/:id", handlers.UpdateAccount)
	protected.DELETE("/finance/coa/:id", handlers.DeleteAccount)
	protected.GET("/finance/journal", handlers.GetJournal)
	protected.GET("/finance/ledger", handlers.GetGeneralLedger)

	// ─── Stock & Ingredients ──────────────────────────────────────────────────
	// ─── WA Logs ─────────────────────────────────────────────────────────────
	protected.GET("/wa-logs", handlers.GetWALogs)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	r.Run(":" + port)
}
