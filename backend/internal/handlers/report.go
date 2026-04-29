package handlers

import (
	"fmt"
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/middleware"
	"pos-resto/backend/internal/models"
	"time"

	"github.com/gin-gonic/gin"
)

type SalesReport struct {
	TotalRevenue    float64            `json:"total_revenue"`
	TotalOrders     int64              `json:"total_orders"`
	PaymentMethodSummary []PaymentSummary `json:"payment_summary"`
	BestSellers     []MenuItemStats    `json:"best_sellers"`
}

type PaymentSummary struct {
	Method string  `json:"method"`
	Count  int64   `json:"count"`
	Total  float64 `json:"total"`
}

type MenuItemStats struct {
	MenuID   uint    `json:"menu_id"`
	Name     string  `json:"name"`
	Quantity int     `json:"quantity"`
	Revenue  float64 `json:"revenue"`
}

func GetFinancialReport(c *gin.Context) {
	startDateStr := c.Query("start_date") // YYYY-MM-DD
	endDateStr := c.Query("end_date")

	var startDate, endDate time.Time
	if startDateStr != "" {
		startDate, _ = time.Parse("2006-01-02", startDateStr)
	} else {
		startDate = time.Now().AddDate(0, 0, -30) // Default last 30 days
	}

	if endDateStr != "" {
		endDate, _ = time.Parse("2006-01-02", endDateStr)
		endDate = endDate.Add(24 * time.Hour) // Include the end date
	} else {
		endDate = time.Now().Add(24 * time.Hour)
	}

	var report SalesReport

	// 1. Total Revenue & Orders
	db := database.DB.Model(&models.Order{}).Scopes(middleware.GetQueryScope(c)).
		Where("status = 'Selesai' AND created_at BETWEEN ? AND ?", startDate, endDate)

	db.Count(&report.TotalOrders)
	db.Select("SUM(total_amount)").Scan(&report.TotalRevenue)

	// 2. Payment Method Summary
	database.DB.Table("payments").
		Select("payment_method as method, count(*) as count, sum(amount_paid - change) as total").
		Joins("join orders on orders.id = payments.order_id").
		Scopes(middleware.GetQueryScope(c)).
		Where("orders.status = 'Selesai' AND payments.created_at BETWEEN ? AND ?", startDate, endDate).
		Group("payment_method").
		Scan(&report.PaymentMethodSummary)

	// 3. Best Sellers
	database.DB.Table("order_items").
		Select("menu_id, menus.name, sum(quantity) as quantity, sum(subtotal) as revenue").
		Joins("join orders on orders.id = order_items.order_id").
		Joins("join menus on menus.id = order_items.menu_id").
		Scopes(middleware.GetQueryScope(c)).
		Where("orders.status = 'Selesai' AND orders.created_at BETWEEN ? AND ?", startDate, endDate).
		Group("menu_id, menus.name").
		Order("quantity DESC").
		Limit(10).
		Scan(&report.BestSellers)

	c.JSON(http.StatusOK, report)
}

func ExportFinancialCSV(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	var startDate, endDate time.Time
	if startDateStr != "" {
		startDate, _ = time.Parse("2006-01-02", startDateStr)
	} else {
		startDate = time.Now().AddDate(0, 0, -30)
	}

	if endDateStr != "" {
		endDate, _ = time.Parse("2006-01-02", endDateStr)
		endDate = endDate.Add(24 * time.Hour)
	} else {
		endDate = time.Now().Add(24 * time.Hour)
	}

	type CSVRow struct {
		ID            uint      `gorm:"column:id"`
		CreatedAt     time.Time `gorm:"column:created_at"`
		CustomerName  string    `gorm:"column:customer_name"`
		TotalAmount   float64   `gorm:"column:total_amount"`
		PaymentMethod string    `gorm:"column:payment_method"`
		Status        string    `gorm:"column:status"`
	}

	var rows []CSVRow

	database.DB.Table("orders").
		Select("orders.id, orders.created_at, orders.customer_name, orders.total_amount, payments.payment_method, orders.status").
		Joins("left join payments on payments.order_id = orders.id").
		Scopes(middleware.GetQueryScope(c)).
		Where("orders.created_at BETWEEN ? AND ?", startDate, endDate).
		Order("orders.created_at DESC").
		Scan(&rows)

	// Build CSV
	csvContent := "ID,Tanggal,Pelanggan,Total,Metode Pembayaran,Status\n"
	for _, row := range rows {
		dateStr := row.CreatedAt.Format("2006-01-02 15:04:05")
		// Simple escaping for customer name if it contains commas
		custName := row.CustomerName
		if custName == "" {
			custName = "-"
		}
		
		csvContent += fmt.Sprintf("%d,%s,\"%s\",%.2f,%s,%s\n", 
			row.ID, dateStr, custName, row.TotalAmount, row.PaymentMethod, row.Status)
	}

	c.Header("Content-Disposition", "attachment; filename=Laporan_Penjualan.csv")
	c.Header("Content-Type", "text/csv")
	c.String(http.StatusOK, csvContent)
}

type IngredientConsumption struct {
	IngredientID uint    `json:"ingredient_id"`
	Name         string  `json:"name"`
	Unit         string  `json:"unit"`
	TotalQty     float64 `json:"total_qty"`
	TotalCost    float64 `json:"total_cost"`
}

func GetIngredientConsumptionReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")

	var startDate, endDate time.Time
	if startDateStr != "" {
		startDate, _ = time.Parse("2006-01-02", startDateStr)
	} else {
		startDate = time.Now().AddDate(0, 0, -30)
	}

	if endDateStr != "" {
		endDate, _ = time.Parse("2006-01-02", endDateStr)
		endDate = endDate.Add(24 * time.Hour)
	} else {
		endDate = time.Now().Add(24 * time.Hour)
	}

	var consumption []IngredientConsumption

	database.DB.Table("order_items").
		Select("ingredients.id as ingredient_id, ingredients.name, ingredients.unit, sum(order_items.quantity * menu_ingredients.qty_used) as total_qty, sum(order_items.quantity * menu_ingredients.qty_used * ingredients.cost_per_unit) as total_cost").
		Joins("join orders on orders.id = order_items.order_id").
		Joins("join menu_ingredients on menu_ingredients.menu_id = order_items.menu_id").
		Joins("join ingredients on ingredients.id = menu_ingredients.ingredient_id").
		Scopes(middleware.GetQueryScope(c)).
		Where("orders.status = 'Selesai' AND orders.created_at BETWEEN ? AND ?", startDate, endDate).
		Group("ingredients.id, ingredients.name, ingredients.unit").
		Scan(&consumption)

	c.JSON(http.StatusOK, consumption)
}

type DetailedSalesReportRow struct {
	ID             uint      `json:"id"`
	CreatedAt      time.Time `json:"created_at"`
	CustomerName   string    `json:"customer_name"`
	TotalAmount    float64   `json:"total_amount"`
	TaxAmount      float64   `json:"tax_amount"`
	ServiceCharge  float64   `json:"service_charge"`
	DiscountAmount float64   `json:"discount_amount"`
	PaymentMethod  string    `json:"payment_method"`
	OrderSource    string    `json:"order_source"`
	DeliveryMethod string    `json:"delivery_method"`
	Status         string    `json:"status"`
	BranchName     string    `json:"branch_name"`
}

func GetDetailedSalesReport(c *gin.Context) {
	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")
	branchID := c.Query("branch_id")
	paymentMethod := c.Query("payment_method")
	orderSource := c.Query("order_source")
	deliveryMethod := c.Query("delivery_method")

	var startDate, endDate time.Time
	if startDateStr != "" {
		startDate, _ = time.Parse("2006-01-02", startDateStr)
	} else {
		startDate = time.Now().AddDate(0, 0, -30)
	}

	if endDateStr != "" {
		endDate, _ = time.Parse("2006-01-02", endDateStr)
		endDate = endDate.Add(23*time.Hour + 59*time.Minute + 59*time.Second)
	} else {
		endDate = time.Now()
	}

	var rows []DetailedSalesReportRow
	db := database.DB.Table("orders").
		Select("orders.id, orders.created_at, orders.customer_name, orders.total_amount, orders.tax_amount, orders.service_charge_amount as service_charge, orders.discount_amount, payments.payment_method, orders.order_source, orders.delivery_method, orders.status, branches.name as branch_name").
		Joins("left join payments on payments.order_id = orders.id").
		Joins("left join branches on branches.id = orders.branch_id").
		Scopes(middleware.GetQueryScope(c)).
		Where("orders.created_at BETWEEN ? AND ?", startDate, endDate)

	if branchID != "" {
		db = db.Where("orders.branch_id = ?", branchID)
	}
	if paymentMethod != "" {
		db = db.Where("payments.payment_method = ?", paymentMethod)
	}
	if orderSource != "" {
		db = db.Where("orders.order_source = ?", orderSource)
	}
	if deliveryMethod != "" {
		db = db.Where("orders.delivery_method = ?", deliveryMethod)
	}

	if err := db.Order("orders.created_at DESC").Scan(&rows).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch report data"})
		return
	}

	c.JSON(http.StatusOK, rows)
}
