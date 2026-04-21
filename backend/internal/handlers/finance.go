package handlers

import (
	"net/http"
	"pos-resto/backend/database"
	"pos-resto/backend/internal/models"
	"time"

	"github.com/gin-gonic/gin"
)

// ─── Chart Of Accounts ───────────────────────────────────────────────────────

func GetCOA(c *gin.Context) {
	var accounts []models.Account
	branchID, _ := c.Get("branchID")
	
	database.DB.Where("branch_id = ? OR branch_id IS NULL", branchID).Order("code asc").Find(&accounts)
	c.JSON(http.StatusOK, accounts)
}

func CreateAccount(c *gin.Context) {
	var account models.Account
	if err := c.ShouldBindJSON(&account); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	branchIDVal, _ := c.Get("branchID")
	branchID := branchIDVal.(uint)
	account.BranchID = &branchID

	if err := database.DB.Create(&account).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create account"})
		return
	}

	c.JSON(http.StatusCreated, account)
}

func UpdateAccount(c *gin.Context) {
	id := c.Param("id")
	var account models.Account
	if err := database.DB.First(&account, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Account not found"})
		return
	}

	var req models.Account
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	req.ID = account.ID
	req.CreatedAt = account.CreatedAt
	branchIDVal, _ := c.Get("branchID")
	branchID := branchIDVal.(uint)
	req.BranchID = &branchID

	if err := database.DB.Save(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update account"})
		return
	}

	c.JSON(http.StatusOK, req)
}

func DeleteAccount(c *gin.Context) {
	id := c.Param("id")
	if err := database.DB.Delete(&models.Account{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete account"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Account deleted successfully"})
}

// ─── Journal Entries ─────────────────────────────────────────────────────────

func GetJournal(c *gin.Context) {
	var entries []models.JournalEntry
	branchID, _ := c.Get("branchID")

	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	db := database.DB.Where("branch_id = ?", branchID).Preload("Items.Account")

	if startDate != "" && endDate != "" {
		db = db.Where("date BETWEEN ? AND ?", startDate, endDate)
	}

	if err := db.Order("date desc, created_at desc").Find(&entries).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch journal entries"})
		return
	}

	c.JSON(http.StatusOK, entries)
}

type GeneralLedgerRow struct {
	AccountID   uint      `json:"account_id"`
	AccountName string    `json:"account_name"`
	AccountCode string    `json:"account_code"`
	Date        time.Time `json:"date"`
	Description string    `json:"description"`
	Reference   string    `json:"reference"`
	Debit       float64   `json:"debit"`
	Credit      float64   `json:"credit"`
	Balance     float64   `json:"balance"`
}

func GetGeneralLedger(c *gin.Context) {
	branchID, _ := c.Get("branchID")
	accountID := c.Query("account_id")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	if accountID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Account ID is required"})
		return
	}

	var journalItems []models.JournalItem
	db := database.DB.Preload("Account").Preload("Journal").
		Joins("JOIN journal_entries ON journal_entries.id = journal_items.journal_id").
		Where("journal_entries.branch_id = ? AND journal_items.account_id = ?", branchID, accountID)

	if startDate != "" && endDate != "" {
		db = db.Where("journal_entries.date BETWEEN ? AND ?", startDate, endDate)
	}

	if err := db.Order("journal_entries.date asc").Find(&journalItems).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch ledger"})
		return
	}

	// Calculate running balance
	var ledger []GeneralLedgerRow
	var runningBalance float64
	for _, item := range journalItems {
		runningBalance += (item.Debit - item.Credit)
		ledger = append(ledger, GeneralLedgerRow{
			AccountID:   item.AccountID,
			AccountName: item.Account.Name,
			AccountCode: item.Account.Code,
			Date:        item.Journal.Date,
			Description: item.Journal.Description,
			Reference:   item.Journal.Reference,
			Debit:       item.Debit,
			Credit:      item.Credit,
			Balance:     runningBalance,
		})
	}

	c.JSON(http.StatusOK, ledger)
}

// ─── Utility ───────────────────────────────────────────────────────────────

func SeedDefaultCOA(branchID uint) {
	defaults := []models.Account{
		{BranchID: &branchID, Code: "1101", Name: "Kas", Type: "Asset", Description: "Kas di Tangan"},
		{BranchID: &branchID, Code: "1102", Name: "Bank", Type: "Asset", Description: "Rekening Bank"},
		{BranchID: &branchID, Code: "1201", Name: "Persediaan Bahan Baku", Type: "Asset", Description: "Stok bahan baku dapur"},
		{BranchID: &branchID, Code: "2101", Name: "Hutang PPN", Type: "Liability", Description: "Pajak Pertambahan Nilai yang belum disetor"},
		{BranchID: &branchID, Code: "3101", Name: "Modal Pemilik", Type: "Equity", Description: "Modal awal usaha"},
		{BranchID: &branchID, Code: "4101", Name: "Pendapatan Penjualan", Type: "Revenue", Description: "Hasil penjualan makanan & minuman"},
		{BranchID: &branchID, Code: "4102", Name: "Pendapatan Service Charge", Type: "Revenue", Description: "Hasil biaya layanan"},
		{BranchID: &branchID, Code: "5101", Name: "Harga Pokok Penjualan (HPP)", Type: "Expense", Description: "Biaya bahan baku terjual"},
		{BranchID: &branchID, Code: "5201", Name: "Biaya Gaji", Type: "Expense", Description: "Pengeluaran untuk gaji karyawan"},
		{BranchID: &branchID, Code: "5202", Name: "Biaya Listrik & Air", Type: "Expense", Description: "Operasional utilitas"},
	}

	for _, acc := range defaults {
		var existing models.Account
		if err := database.DB.Where("branch_id = ? AND code = ?", branchID, acc.Code).First(&existing).Error; err != nil {
			database.DB.Create(&acc)
		}
	}
}
