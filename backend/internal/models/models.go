package models

import (
	"time"
)

// ─── Auth ────────────────────────────────────────────────────────────────────

type Role struct {
	ID          uint          `gorm:"primaryKey" json:"id"`
	Name        string        `gorm:"unique;not null;type:varchar(50)" json:"name"`
	Description string        `json:"description"`
	Menus       []SidebarMenu `gorm:"many2many:role_menus;" json:"menus,omitempty"`
}

type SidebarMenu struct {
	ID        uint          `gorm:"primaryKey" json:"id"`
	ParentID  *uint         `json:"parent_id"`
	Title     string        `gorm:"not null" json:"title"`
	Path      string        `json:"path"`
	Icon      string        `json:"icon"`
	SortOrder int           `gorm:"default:0" json:"sort_order"`
	IsHeader  bool          `gorm:"default:false" json:"is_header"`
	Children  []SidebarMenu `gorm:"foreignKey:ParentID" json:"children,omitempty"`
}

type Company struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Name      string    `gorm:"not null;type:varchar(150)" json:"name"`
	Code      string    `gorm:"unique;not null;type:varchar(50)" json:"code"`
	Address   string    `json:"address"`
	Phone     string    `gorm:"type:varchar(20)" json:"phone"`
	Email     string    `gorm:"type:varchar(100)" json:"email"`
	LogoURL   string    `json:"logo_url"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
}

type Branch struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	CompanyID uint      `json:"company_id"`
	Company   *Company  `gorm:"foreignKey:CompanyID" json:"company,omitempty"`
	Name      string    `gorm:"not null;type:varchar(150)" json:"name"`
	Code      string    `gorm:"unique;not null;type:varchar(50)" json:"code"`
	Address   string    `json:"address"`
	Phone     string    `gorm:"type:varchar(20)" json:"phone"`
	Email     string    `gorm:"type:varchar(100)" json:"email"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
}

type User struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	CompanyID    uint      `json:"company_id"`
	Company      *Company  `gorm:"foreignKey:CompanyID" json:"company,omitempty"`
	FullName     string    `gorm:"type:varchar(100)" json:"full_name"`
	Username     string    `gorm:"unique;not null;type:varchar(50)" json:"username"`
	PasswordHash string    `gorm:"not null" json:"-"`
	RoleID       uint      `json:"role_id"`
	Role         Role      `gorm:"foreignKey:RoleID" json:"role"`
	BranchID     *uint     `json:"branch_id"`
	Branch       *Branch   `gorm:"foreignKey:BranchID" json:"branch"`
	IsActive     bool      `gorm:"default:true" json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
}

// ─── Menu ─────────────────────────────────────────────────────────────────────

type Category struct {
	ID          uint    `gorm:"primaryKey" json:"id"`
	CompanyID   uint    `json:"company_id"`
	BranchID    *uint   `json:"branch_id"`
	Name        string  `gorm:"unique;not null;type:varchar(100)" json:"name"`
	Description string  `json:"description"`
}

type Menu struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	CompanyID   uint      `json:"company_id"`
	BranchID    *uint     `json:"branch_id"`
	CategoryID  uint      `json:"category_id"`
	Category    Category  `gorm:"foreignKey:CategoryID" json:"category"`
	Name        string    `gorm:"not null;type:varchar(150)" json:"name"`
	Description string    `json:"description"`
	Price       float64   `gorm:"not null" json:"price"`
	Stock       int       `gorm:"default:0" json:"stock"`
	ImageURL    string    `json:"image_url"`
	IsAvailable bool      `gorm:"default:true" json:"is_available"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// ─── Ingredient & Recipe ──────────────────────────────────────────────────────

type Ingredient struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	CompanyID    uint      `json:"company_id"`
	BranchID     *uint     `json:"branch_id"`
	Name         string    `gorm:"not null;type:varchar(100)" json:"name"`
	Unit         string    `gorm:"not null;type:varchar(20)" json:"unit"` // gram, ml, pcs, etc.
	Stock        float64   `gorm:"default:0" json:"stock"`
	CostPerUnit  float64   `gorm:"default:0" json:"cost_per_unit"`
	MinStock     float64   `gorm:"default:0" json:"min_stock"`
	SupplierID   *uint     `json:"supplier_id"`
	Supplier     *Supplier `gorm:"foreignKey:SupplierID" json:"supplier"`
	CreatedAt    time.Time `json:"created_at"`
}

type MenuIngredient struct {
	ID           uint       `gorm:"primaryKey" json:"id"`
	MenuID       uint       `gorm:"not null" json:"menu_id"`
	Menu         Menu       `gorm:"foreignKey:MenuID" json:"menu"`
	IngredientID uint       `gorm:"not null" json:"ingredient_id"`
	Ingredient   Ingredient `gorm:"foreignKey:IngredientID" json:"ingredient"`
	QtyUsed      float64    `gorm:"not null" json:"qty_used"`
	Unit         string     `gorm:"type:varchar(20)" json:"unit"`
}

// ─── Supplier ─────────────────────────────────────────────────────────────────

type Supplier struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	CompanyID     uint      `json:"company_id"`
	BranchID      *uint     `json:"branch_id"`
	Name          string    `gorm:"not null;type:varchar(150)" json:"name"`
	ContactPerson string    `gorm:"type:varchar(100)" json:"contact_person"`
	Phone         string    `gorm:"type:varchar(20)" json:"phone"`
	Email         string    `gorm:"type:varchar(100)" json:"email"`
	Address       string    `json:"address"`
	Notes         string    `json:"notes"`
	IsActive      bool      `gorm:"default:true" json:"is_active"`
	CreatedAt     time.Time `json:"created_at"`
}

// ─── Customer ─────────────────────────────────────────────────────────────────

type Customer struct {
	ID             uint      `gorm:"primaryKey" json:"id"`
	CompanyID      uint      `json:"company_id"`
	BranchID       *uint     `json:"branch_id"`
	Name           string    `gorm:"not null;type:varchar(100)" json:"name"`
	Phone          string    `gorm:"type:varchar(20)" json:"phone"`
	Email          string    `gorm:"type:varchar(100)" json:"email"`
	Address        string    `json:"address"`
	LoyaltyPoints  int       `gorm:"default:0" json:"loyalty_points"`
	TotalSpent     float64   `gorm:"default:0" json:"total_spent"`
	Tier           string    `gorm:"default:'Bronze';type:varchar(20)" json:"tier"` // Bronze, Silver, Gold
	IsSendWA       bool      `gorm:"default:false" json:"is_send_wa"`
	CreatedAt      time.Time `json:"created_at"`
}

// ─── Promo ────────────────────────────────────────────────────────────────────

type Promo struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	CompanyID    uint      `json:"company_id"`
	BranchID     *uint     `json:"branch_id"`
	Name         string    `gorm:"not null;type:varchar(100)" json:"name"`
	Description  string    `json:"description"`
	Type         string    `gorm:"not null;type:varchar(20)" json:"type"` // percentage, flat
	Value        float64   `gorm:"not null" json:"value"`
	MinOrder     float64   `gorm:"default:0" json:"min_order"`
	MaxDiscount  float64   `gorm:"default:0" json:"max_discount"` // 0 = no limit
	StartDate    time.Time `json:"start_date"`
	EndDate      time.Time `json:"end_date"`
	IsActive     bool      `gorm:"default:true" json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
}

// ─── Table ────────────────────────────────────────────────────────────────────

type Table struct {
	ID          uint    `gorm:"primaryKey" json:"id"`
	CompanyID   uint    `json:"company_id"`
	BranchID    uint    `json:"branch_id"`
	Branch      Branch  `gorm:"foreignKey:BranchID" json:"branch"`
	TableNumber string  `gorm:"not null;type:varchar(10)" json:"table_number"`
	Capacity    int     `gorm:"default:4" json:"capacity"`
	Floor       string  `gorm:"type:varchar(20)" json:"floor"`
	ImageURL    string  `json:"image_url"`
	PositionX   float64 `gorm:"default:0" json:"position_x"`
	PositionY   float64 `gorm:"default:0" json:"position_y"`
	Status      string  `gorm:"default:'Kosong';type:varchar(20)" json:"status"` // Kosong, Dipesan, Digunakan
}

// ─── Order ────────────────────────────────────────────────────────────────────

type Order struct {
	ID             uint        `gorm:"primaryKey" json:"id"`
	CompanyID      uint        `json:"company_id"`
	BranchID       uint        `json:"branch_id"`
	Branch         Branch      `gorm:"foreignKey:BranchID" json:"branch"`
	TableID        *uint       `json:"table_id"`
	Table          Table       `gorm:"foreignKey:TableID" json:"table"`
	UserID         uint        `json:"user_id"`
	User           User        `gorm:"foreignKey:UserID" json:"user"`
	CustomerID     *uint       `json:"customer_id"`
	Customer       *Customer   `gorm:"foreignKey:CustomerID" json:"customer"`
	CustomerName   string      `json:"customer_name"`
	PromoID        *uint       `json:"promo_id"`
	Promo          *Promo      `gorm:"foreignKey:PromoID" json:"promo"`
	Status         string      `gorm:"default:'Pending';type:varchar(20)" json:"status"` // Pending, Proses, Selesai, Batal
	TotalAmount    float64     `gorm:"default:0" json:"total_amount"`
	TaxAmount      float64     `gorm:"default:0" json:"tax_amount"`
	DiscountAmount float64     `gorm:"default:0" json:"discount_amount"`
	ShippingFee    float64     `gorm:"default:0" json:"shipping_fee"`
	Notes          string      `json:"notes"`
	IsPaid         bool        `gorm:"default:false" json:"is_paid"`
	CreatedAt      time.Time   `json:"created_at"`
	Items          []OrderItem `gorm:"foreignKey:OrderID" json:"items"`
	ServiceChargeAmount float64 `gorm:"default:0" json:"service_charge_amount"`
	VoidReason     string      `json:"void_reason"`
	OrderSource    string      `gorm:"type:varchar(50);default:'Resto'" json:"order_source"`
	DeliveryMethod string      `gorm:"type:varchar(50);default:'Dine In'" json:"delivery_method"`
}

type OrderItem struct {
	ID       uint    `gorm:"primaryKey" json:"id"`
	OrderID  uint    `gorm:"not null" json:"order_id"`
	MenuID   uint    `gorm:"not null" json:"menu_id"`
	Menu     Menu    `gorm:"foreignKey:MenuID" json:"menu"`
	Quantity int     `gorm:"not null" json:"quantity"`
	Price    float64 `gorm:"not null" json:"price"`
	Subtotal float64 `gorm:"not null" json:"subtotal"`
	Notes    string  `json:"notes"`
	IsReady  bool    `gorm:"default:false" json:"is_ready"`
}

// ─── Payment ──────────────────────────────────────────────────────────────────

type Payment struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	CompanyID     uint      `json:"company_id"`
	BranchID      uint      `json:"branch_id"`
	OrderID       uint      `gorm:"not null;unique" json:"order_id"`
	Order         Order     `gorm:"foreignKey:OrderID" json:"order"`
	AmountPaid    float64   `gorm:"not null" json:"amount_paid"`
	Change        float64   `gorm:"default:0" json:"change"`
	PaymentMethod string    `gorm:"not null;type:varchar(50)" json:"payment_method"` // Tunai, QRIS, E-Wallet, Transfer Bank, Kartu Debit/Kredit
	ReferenceNo   string    `gorm:"type:varchar(100)" json:"reference_no"`
	CreatedAt     time.Time `json:"created_at"`
}

// ─── Cashier Session ──────────────────────────────────────────────────────────

type CashierSession struct {
	ID           uint       `gorm:"primaryKey" json:"id"`
	CompanyID    uint       `json:"company_id"`
	BranchID     uint       `json:"branch_id"`
	UserID       uint       `gorm:"not null" json:"user_id"`
	User         User       `gorm:"foreignKey:UserID" json:"user"`
	OpenTime     time.Time  `gorm:"not null" json:"open_time"`
	CloseTime    *time.Time `json:"close_time"`
	InitialCash  float64    `gorm:"not null;default:0" json:"initial_cash"`
	ClosingCash  float64    `gorm:"default:0" json:"closing_cash"`
	TotalSales   float64    `gorm:"default:0" json:"total_sales"`
	TotalOrders  int        `gorm:"default:0" json:"total_orders"`
	Notes        string     `json:"notes"`
	Status       string     `gorm:"default:'Open';type:varchar(10)" json:"status"` // Open, Closed
}

// ─── Settings ────────────────────────────────────────────────────────────────

type SystemSetting struct {
	ID        uint   `gorm:"primaryKey" json:"id"`
	CompanyID uint   `json:"company_id"`
	BranchID  *uint  `gorm:"uniqueIndex:idx_branch_key" json:"branch_id"`
	Key       string `gorm:"uniqueIndex:idx_branch_key;not null;type:varchar(50)" json:"key"` // tax_pct, service_charge_pct
	Value     string `gorm:"not null" json:"value"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// ─── Finance ──────────────────────────────────────────────────────────────────

type Account struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	CompanyID   uint      `json:"company_id"`
	BranchID    *uint     `json:"branch_id"`
	Code        string    `gorm:"uniqueIndex:idx_branch_code;not null;type:varchar(20)" json:"code"`
	Name        string    `gorm:"not null;type:varchar(100)" json:"name"`
	Type        string    `gorm:"not null;type:varchar(50)" json:"type"` // Asset, Liability, Equity, Revenue, Expense
	Description string    `json:"description"`
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

type JournalEntry struct {
	ID          uint          `gorm:"primaryKey" json:"id"`
	CompanyID   uint          `json:"company_id"`
	BranchID    uint          `json:"branch_id"`
	Date        time.Time     `gorm:"not null" json:"date"`
	Description string        `json:"description"`
	Reference   string        `gorm:"type:varchar(100)" json:"reference"` // Order ID, Manual, etc.
	TotalAmount float64       `json:"total_amount"`
	Items       []JournalItem `gorm:"foreignKey:JournalID" json:"items"`
	CreatedAt   time.Time     `json:"created_at"`
}

type JournalItem struct {
	ID        uint         `gorm:"primaryKey" json:"id"`
	CompanyID uint         `json:"company_id"`
	BranchID  uint         `json:"branch_id"`
	JournalID uint         `gorm:"not null" json:"journal_id"`
	Journal   JournalEntry `gorm:"foreignKey:JournalID" json:"journal"`
	AccountID uint         `gorm:"not null" json:"account_id"`
	Account   Account      `gorm:"foreignKey:AccountID" json:"account"`
	Debit     float64      `gorm:"default:0" json:"debit"`
	Credit    float64      `gorm:"default:0" json:"credit"`
}

type StockHistory struct {
	ID           uint       `gorm:"primaryKey" json:"id"`
	CompanyID    uint       `json:"company_id"`
	BranchID     uint       `json:"branch_id"`
	Branch       *Branch    `gorm:"foreignKey:BranchID" json:"branch,omitempty"`
	UserID       uint       `json:"user_id"`
	User         *User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	IngredientID uint       `gorm:"not null" json:"ingredient_id"`
	Ingredient   Ingredient `gorm:"foreignKey:IngredientID" json:"ingredient"`
	OrderID      *uint      `json:"order_id"`
	Order        *Order     `gorm:"foreignKey:OrderID" json:"order,omitempty"`
	Type         string     `gorm:"not null;type:varchar(20)" json:"type"` // IN, OUT, ADJUST, WASTE, VOID
	Quantity     float64    `gorm:"not null" json:"quantity"`
	Notes        string     `json:"notes"`
	CreatedAt    time.Time  `json:"created_at"`
}

type WALog struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	CompanyID  uint      `json:"company_id"`
	BranchID   uint      `json:"branch_id"`
	OrderID    uint      `json:"order_id"`
	CustomerID *uint     `json:"customer_id"`
	Phone      string    `json:"phone"`
	Message    string    `json:"message"`
	Status     string    `json:"status"` // Success, Failed
	CreatedAt  time.Time `json:"created_at"`
}

// ─── Goods Receipt & Issue (Inventory Management) ──────────────────────────

type GoodsReceipt struct {
	ID          uint               `gorm:"primaryKey" json:"id"`
	CompanyID   uint               `json:"company_id"`
	BranchID    uint               `json:"branch_id"`
	Branch      Branch             `gorm:"foreignKey:BranchID" json:"branch"`
	SupplierID      *uint              `json:"supplier_id"`
	Supplier        *Supplier          `gorm:"foreignKey:SupplierID" json:"supplier"`
	ReceiptNo       string             `gorm:"unique;not null;type:varchar(50)" json:"receipt_no"`
	VendorInvoiceNo string             `gorm:"type:varchar(50)" json:"vendor_invoice_no"`
	ReceiptDate     time.Time          `gorm:"not null" json:"receipt_date"`
	BranchOrderID   *uint              `json:"branch_order_id"`
	TotalAmount     float64            `gorm:"default:0" json:"total_amount"`
	Notes           string             `json:"notes"`
	ReceivedBy      string             `gorm:"type:varchar(100)" json:"received_by"`
	Status          string             `gorm:"default:'Draft';type:varchar(20)" json:"status"` // Draft, Approved, Cancelled
	CreatedAt       time.Time          `json:"created_at"`
	Items       []GoodsReceiptItem `gorm:"foreignKey:ReceiptID" json:"items"`
}

type GoodsReceiptItem struct {
	ID           uint       `gorm:"primaryKey" json:"id"`
	ReceiptID    uint       `gorm:"not null" json:"receipt_id"`
	IngredientID uint       `gorm:"not null" json:"ingredient_id"`
	Ingredient   Ingredient `gorm:"foreignKey:IngredientID" json:"ingredient"`
	Quantity     float64    `gorm:"not null" json:"quantity"`
	CostPrice    float64    `gorm:"not null" json:"cost_price"`
	Subtotal     float64    `gorm:"not null" json:"subtotal"`
}

type GoodsIssue struct {
	ID        uint             `gorm:"primaryKey" json:"id"`
	CompanyID uint             `json:"company_id"`
	BranchID  uint             `json:"branch_id"`
	Branch    Branch           `gorm:"foreignKey:BranchID" json:"branch"`
	IssueNo       string           `gorm:"unique;not null;type:varchar(50)" json:"issue_no"`
	IssueCategory string           `gorm:"type:varchar(50)" json:"issue_category"` // Waste, Transfer, Sales Adjustment
	IssueDate     time.Time        `gorm:"not null" json:"issue_date"`
	Notes         string           `json:"notes"`
	IssuedBy      string           `gorm:"type:varchar(100)" json:"issued_by"`
	Status        string           `gorm:"default:'Draft';type:varchar(20)" json:"status"` // Draft, Approved, Cancelled
	CreatedAt     time.Time        `json:"created_at"`
	Items     []GoodsIssueItem `gorm:"foreignKey:IssueID" json:"items"`
}

type GoodsIssueItem struct {
	ID           uint       `gorm:"primaryKey" json:"id"`
	IssueID      uint       `gorm:"not null" json:"issue_id"`
	IngredientID uint       `gorm:"not null" json:"ingredient_id"`
	Ingredient   Ingredient `gorm:"foreignKey:IngredientID" json:"ingredient"`
	Quantity     float64    `gorm:"not null" json:"quantity"`
	Notes        string     `json:"notes"`
}

// ─── Branch Order (Request to Center) ─────────────────────────────────────────

type BranchOrder struct {
	ID          uint               `gorm:"primaryKey" json:"id"`
	CompanyID   uint               `json:"company_id"`
	BranchID    uint               `json:"branch_id"`
	Branch      Branch             `gorm:"foreignKey:BranchID" json:"branch"`
	OrderNo     string             `gorm:"unique;not null;type:varchar(50)" json:"order_no"`
	OrderDate   time.Time          `gorm:"not null" json:"order_date"`
	Notes       string             `json:"notes"`
	RequestedBy string             `gorm:"type:varchar(100)" json:"requested_by"`
	Status      string             `gorm:"default:'Pending';type:varchar(20)" json:"status"` // Pending, Approved, Adjusted, Fulfilled, Cancelled
	CreatedAt   time.Time          `json:"created_at"`
	Items       []BranchOrderItem  `gorm:"foreignKey:BranchOrderID" json:"items"`
}

type BranchOrderItem struct {
	ID            uint       `gorm:"primaryKey" json:"id"`
	BranchOrderID uint       `gorm:"not null" json:"branch_order_id"`
	IngredientID  uint       `gorm:"not null" json:"ingredient_id"`
	Ingredient    Ingredient `gorm:"foreignKey:IngredientID" json:"ingredient"`
	Quantity      float64    `gorm:"not null" json:"quantity"`
	ApprovedQty   float64    `json:"approved_qty"`
	Notes         string     `json:"notes"`
}

// ─── Trial Registration (Landing Page) ────────────────────────────────────────

type TrialRegistration struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	FullName     string    `gorm:"type:varchar(100)" json:"full_name"`
	Email        string    `gorm:"type:varchar(100)" json:"email"`
	Phone        string    `gorm:"type:varchar(20)" json:"phone"`
	BusinessName string    `gorm:"type:varchar(150)" json:"business_name"`
	BusinessAddress string  `gorm:"type:text" json:"business_address"`
	BusinessCategory string `gorm:"type:varchar(50)" json:"business_category"`
	Status       string    `gorm:"default:'Pending';type:varchar(20)" json:"status"` // Pending, Approved, Rejected
	CreatedAt    time.Time `json:"created_at"`
}
