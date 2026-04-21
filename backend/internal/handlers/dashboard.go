package handlers

import (
	"net/http"
	"time"

	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"

	"github.com/gin-gonic/gin"
)

func GetDashboardStats(c *gin.Context) {
	var totalOrdersToday int64
	var totalRevenueToday float64
	var activeTables int64
	var availableTables int64

	now := time.Now()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	// Total Orders Today
	database.DB.Model(&models.Order{}).Scopes(middleware.GetQueryScope(c)).Where("created_at >= ?", startOfDay).Count(&totalOrdersToday)

	// Total Revenue Today (Only completed orders)
	database.DB.Model(&models.Order{}).Scopes(middleware.GetQueryScope(c)).
		Where("created_at >= ? AND status = ?", startOfDay, "Selesai").
		Select("COALESCE(SUM(total_amount), 0)").
		Row().Scan(&totalRevenueToday)

	// Tables Status
	database.DB.Model(&models.Table{}).Scopes(middleware.GetQueryScope(c)).Where("status = ?", "Digunakan").Count(&activeTables)
	database.DB.Model(&models.Table{}).Scopes(middleware.GetQueryScope(c)).Where("status = ?", "Kosong").Count(&availableTables)

	// Recent Orders (Last 5)
	var recentOrders []models.Order
	database.DB.Model(&models.Order{}).Scopes(middleware.GetQueryScope(c)).Preload("Table").Preload("User").Preload("Customer").
		Order("created_at desc").Limit(5).Find(&recentOrders)

	// Low Stock Ingredients (Stock <= 10)
	var lowStockIngredients []models.Ingredient
	database.DB.Model(&models.Ingredient{}).Scopes(middleware.GetQueryScope(c)).Where("stock <= ?", 10).Limit(10).Find(&lowStockIngredients)

	// Revenue Chart (Last 7 Days)
	var revenueChart []map[string]interface{}
	sevenDaysAgo := startOfDay.AddDate(0, 0, -6) // Include today = 7 days
	
	type DailyRevenue struct {
		Date  string  `json:"date"`
		Total float64 `json:"total"`
	}
	var dailyData []DailyRevenue

	// Using raw SQL to group by date
	database.DB.Model(&models.Order{}).Scopes(middleware.GetQueryScope(c)).
		Select("DATE(created_at) as date, SUM(total_amount) as total").
		Where("created_at >= ? AND status = ?", sevenDaysAgo, "Selesai").
		Group("DATE(created_at)").
		Order("DATE(created_at) ASC").
		Scan(&dailyData)
		
	// Create map for easy lookup
	revenueMap := make(map[string]float64)
	for _, data := range dailyData {
		// format date to YYYY-MM-DD
		parsedDate, _ := time.Parse(time.RFC3339, data.Date+"T00:00:00Z")
		if parsedDate.IsZero() {
			// Some DBs return simple string formats
			revenueMap[data.Date[:10]] = data.Total
		} else {
			revenueMap[parsedDate.Format("2006-01-02")] = data.Total
		}
	}

	// Build chart data array filling missing days with 0
	for i := 0; i < 7; i++ {
		currentDate := sevenDaysAgo.AddDate(0, 0, i).Format("2006-01-02")
		displayLabel := sevenDaysAgo.AddDate(0, 0, i).Format("Mon")
		
		val, exists := revenueMap[currentDate]
		if !exists {
			val = 0
		}
		
		revenueChart = append(revenueChart, map[string]interface{}{
			"label": displayLabel,
			"date":  currentDate,
			"value": val,
		})
	}

	// Top 5 Selling Items Today
	type TopItem struct {
		Name  string  `json:"name"`
		Total float64 `json:"total"`
		Qty   int     `json:"qty"`
	}
	var topItems []TopItem
	database.DB.Table("order_items").
		Select("menus.name as name, SUM(order_items.quantity) as qty, SUM(order_items.subtotal) as total").
		Joins("JOIN menus ON menus.id = order_items.menu_id").
		Joins("JOIN orders ON orders.id = order_items.order_id").
		Where("orders.status = ? AND orders.created_at >= ?", "Selesai", startOfDay).
		Group("menus.name").
		Order("qty DESC").
		Limit(5).
		Scan(&topItems)

	c.JSON(http.StatusOK, gin.H{
		"total_orders_today":   totalOrdersToday,
		"total_revenue_today":  totalRevenueToday,
		"active_tables":        activeTables,
		"available_tables":     availableTables,
		"recent_orders":        recentOrders,
		"low_stock":            lowStockIngredients,
		"revenue_chart":        revenueChart,
		"top_items":            topItems,
	})
}

