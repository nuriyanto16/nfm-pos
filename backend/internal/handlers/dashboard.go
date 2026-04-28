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

func GetExecutiveDashboardStats(c *gin.Context) {
	// Executive dashboard sees data for the entire company
	companyID, exists := c.Get("companyID")
	if !exists {
		c.JSON(http.StatusForbidden, gin.H{"error": "Company ID not found in token"})
		return
	}

	var totalRevenue float64
	var totalOrders int64
	var totalBranches int64
	var totalUsers int64

	// Total Branches in Company
	database.DB.Model(&models.Branch{}).Where("company_id = ?", companyID).Count(&totalBranches)

	// Total Users in Company
	database.DB.Model(&models.User{}).Where("company_id = ?", companyID).Count(&totalUsers)

	// Total Orders in Company (All time)
	database.DB.Model(&models.Order{}).Where("company_id = ?", companyID).Count(&totalOrders)

	// Total Revenue in Company (All time)
	database.DB.Model(&models.Order{}).Where("company_id = ? AND status = ?", companyID, "Selesai").
		Select("COALESCE(SUM(total_amount), 0)").Row().Scan(&totalRevenue)

	// Branch Performance
	type BranchPerformance struct {
		Name    string  `json:"name"`
		Revenue float64 `json:"revenue"`
		Orders  int64   `json:"orders"`
	}
	var branchPerf []BranchPerformance
	database.DB.Table("branches").
		Select("branches.name, COALESCE(SUM(orders.total_amount), 0) as revenue, COUNT(orders.id) as orders").
		Joins("LEFT JOIN orders ON orders.branch_id = branches.id AND orders.status = 'Selesai'").
		Where("branches.company_id = ?", companyID).
		Group("branches.name").
		Order("revenue DESC").
		Scan(&branchPerf)

	// Recent Inventory Activities (Goods Receipt & Issue)
	var recentReceipts []models.GoodsReceipt
	database.DB.Where("company_id = ?", companyID).Preload("Branch").Preload("Supplier").Order("created_at desc").Limit(5).Find(&recentReceipts)

	var recentIssues []models.GoodsIssue
	database.DB.Where("company_id = ?", companyID).Preload("Branch").Order("created_at desc").Limit(5).Find(&recentIssues)

	// Revenue Trend (Last 7 Days)
	var revenueChart []map[string]interface{}
	now := time.Now()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	sevenDaysAgo := startOfDay.AddDate(0, 0, -6)

	type DailyRevenue struct {
		Date  string  `json:"date"`
		Total float64 `json:"total"`
	}
	var dailyData []DailyRevenue
	database.DB.Model(&models.Order{}).
		Select("created_at::date as date, SUM(total_amount) as total").
		Where("company_id = ? AND created_at >= ? AND status = ?", companyID, sevenDaysAgo, "Selesai").
		Group("date").
		Order("date ASC").
		Scan(&dailyData)

	revMap := make(map[string]float64)
	for _, d := range dailyData {
		revMap[d.Date[:10]] = d.Total
	}

	for i := 0; i < 7; i++ {
		d := sevenDaysAgo.AddDate(0, 0, i)
		dateStr := d.Format("2006-01-02")
		revenueChart = append(revenueChart, map[string]interface{}{
			"label": d.Format("Mon"),
			"value": revMap[dateStr],
		})
	}

	// Monthly Revenue Trend (Last 12 Months)
	var monthlyRevenueChart []map[string]interface{}
	twelveMonthsAgo := startOfMonth(now.AddDate(-1, 0, 0))

	type MonthlyRevenue struct {
		Month string  `json:"month"`
		Total float64 `json:"total"`
	}
	var monthlyData []MonthlyRevenue
	database.DB.Model(&models.Order{}).
		Select("to_char(created_at, 'YYYY-MM') as month, SUM(total_amount) as total").
		Where("company_id = ? AND created_at >= ? AND status = ?", companyID, twelveMonthsAgo, "Selesai").
		Group("month").
		Order("month ASC").
		Scan(&monthlyData)

	monMap := make(map[string]float64)
	for _, d := range monthlyData {
		monMap[d.Month] = d.Total
	}

	for i := 0; i < 12; i++ {
		d := twelveMonthsAgo.AddDate(0, i, 0)
		monthKey := d.Format("2006-01")
		monthlyRevenueChart = append(monthlyRevenueChart, map[string]interface{}{
			"label": d.Format("Jan"),
			"value": monMap[monthKey],
		})
	}

	// Branch Orders Tracking Stats
	var pendingOrders int64
	var approvedOrders int64
	var fulfilledOrders int64
	database.DB.Model(&models.BranchOrder{}).Where("company_id = ? AND status = ?", companyID, "Pending").Count(&pendingOrders)
	database.DB.Model(&models.BranchOrder{}).Where("company_id = ? AND status = ?", companyID, "Approved").Count(&approvedOrders)
	database.DB.Model(&models.BranchOrder{}).Where("company_id = ? AND status = ?", companyID, "Fulfilled").Count(&fulfilledOrders)
	
	// Recent Branch Orders
	var recentBranchOrders []models.BranchOrder
	database.DB.Where("company_id = ?", companyID).Preload("Branch").Order("created_at desc").Limit(5).Find(&recentBranchOrders)

	c.JSON(http.StatusOK, gin.H{
		"total_revenue":      totalRevenue,
		"total_orders":       totalOrders,
		"total_branches":     totalBranches,
		"total_users":        totalUsers,
		"branch_performance": branchPerf,
		"recent_receipts":    recentReceipts,
		"recent_issues":      recentIssues,
		"revenue_chart":      revenueChart,
		"monthly_revenue_chart": monthlyRevenueChart,
		"recent_branch_orders": recentBranchOrders,
		"branch_order_stats": gin.H{
			"pending":   pendingOrders,
			"approved":  approvedOrders,
			"fulfilled": fulfilledOrders,
		},
	})
}

func startOfMonth(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), 1, 0, 0, 0, 0, t.Location())
}

