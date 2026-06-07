# 🔄 Diagram Alur Sistem — NFM POS

Dokumen ini berisi diagram alur (flow diagram) untuk seluruh proses bisnis utama dalam platform NFM POS.

---

## 1. Alur Registrasi & Aktivasi SaaS (End-to-End)

```mermaid
flowchart TD
    A([🌐 Pengunjung Landing Page]) --> B[Isi Form Registrasi\nNama, Email, HP, Bisnis, Jenis POS]
    B --> C{Jenis Plan?}

    C -->|UMKM / Free| D["Status: Pending\nIsPaid: ✅ True\n(Gratis, langsung bisa diproses)"]
    C -->|"Bisnis / Franchise\n(Berbayar)"| E["Status: Pending\nIsPaid: ❌ False"]
    
    E --> F[Tampilkan QRIS Payment\nBarcode di Halaman Sukses]
    F --> G[Pengguna Selesaikan Pembayaran]
    G --> H[Kirim Bukti Transfer\nvia WhatsApp ke Admin]

    D --> I{Admin Verifikasi}
    H --> I

    I -->|"Via Aplikasi Admin\n(Frontend Flutter)"| J[Admin Klik Approve\n+ Centang IsPaid]
    I -->|"Via Telegram Bot\n(Command /approve id)"| K[Bot Kirim Request\nPOST /api/registrations/:id/approve]

    J --> L
    K --> L

    L["🔧 Sistem Otomatis:\n1. Buat Company\n2. Buat Branch HQ\n3. Buat User Admin\n4. Generate Sample Menu\n5. Catat StockHistory"] --> M

    M["📱 Kirim Kredensial Login\nvia WhatsApp API\n(username + password)"] --> N([✅ Tenant Aktif\nBisa Login ke Aplikasi])

    style A fill:#4F46E5,color:#fff
    style N fill:#059669,color:#fff
    style L fill:#D97706,color:#fff
```

---

## 2. Alur Login & Akses Sistem

```mermaid
flowchart TD
    Start([👤 User Buka Aplikasi]) --> CheckToken{Token JWT\ntersimpan lokal?}

    CheckToken -->|Ya| ValidateToken{Token\nmasih valid?}
    CheckToken -->|Tidak| ShowLogin[Tampilkan Layar Login]

    ValidateToken -->|Ya| RoleCheck{Cek Role\nUser}
    ValidateToken -->|Expired| ShowLogin

    ShowLogin --> EnterCreds[Masukkan Username\n+ Password]
    EnterCreds --> PostLogin[POST /api/login]
    PostLogin --> AuthResult{Autentikasi\nBerhasil?}
    AuthResult -->|Tidak| ErrorMsg[Tampilkan Error\nUsername/Password Salah]
    ErrorMsg --> ShowLogin
    AuthResult -->|Ya| SaveToken[Simpan JWT Token\ndi SharedPreferences]
    SaveToken --> RoleCheck

    RoleCheck -->|Super User| SuDash[Dashboard Executive\nStatistik Global SaaS]
    RoleCheck -->|Business Owner| BoDash[Dashboard Executive\nData Semua Cabang]
    RoleCheck -->|Kasir/Staff| StaffDash[Layar POS\nCek Sesi Kasir]

    style Start fill:#4F46E5,color:#fff
    style SuDash fill:#7C3AED,color:#fff
    style BoDash fill:#0369A1,color:#fff
    style StaffDash fill:#059669,color:#fff
```

---

## 3. Alur Transaksi POS (Lengkap)

```mermaid
flowchart TD
    Start([👨‍💼 Kasir Buka Aplikasi]) --> CheckSession{Sesi Kasir\nAktif?}

    CheckSession -->|Tidak| OpenSession[Buka Sesi Kasir\nInput Kas Awal]
    CheckSession -->|Ya| PosScreen[Layar POS]
    OpenSession --> PosScreen

    PosScreen --> POSType{Tipe POS\nBisnis?}
    
    POSType -->|Resto| TableSelect[Pilih Meja\n(Status: Kosong)]
    POSType -->|Retail/Fashion/Jasa| DirectOrder[Langsung Pilih Produk]
    
    TableSelect --> SelectMenu[Pilih Menu/Produk\n+ Qty]
    DirectOrder --> SelectMenu
    
    SelectMenu --> AddNotes[Tambah Catatan\n(Opsional)]
    AddNotes --> ApplyPromo[Terapkan Promo\n(Opsional)]
    ApplyPromo --> CreateOrder[POST /api/orders\nBuat Pesanan]

    CreateOrder --> StockCheck{Cek Stok\nOtomatis}
    StockCheck -->|Stok Cukup| OrderCreated[✅ Order Dibuat\nStatus: Pending]
    StockCheck -->|Stok Habis| StockError[❌ Error:\nStok Bahan Tidak Cukup]
    StockError --> SelectMenu

    OrderCreated --> POSTypeStock{Tipe POS?}
    POSTypeStock -->|Retail/Fashion| DeductMenuStock[Potong Menu.Stock\nLangsung]
    POSTypeStock -->|Resto/Jasa| CheckRecipe{Ada Resep\nIngredient?}
    CheckRecipe -->|Ya| DeductIngredient[Potong Ingredient.Stock\n+ Tulis StockHistory]
    CheckRecipe -->|Tidak| NoStockDeduct[Jual Tanpa\nPotong Stok]
    
    DeductMenuStock --> WaitPayment
    DeductIngredient --> WaitPayment
    NoStockDeduct --> WaitPayment

    WaitPayment[⏳ Menunggu Pembayaran] --> ProcessPay[POST /api/orders/:id/pay\nInput Nominal Bayar]
    ProcessPay --> PayMethod{Metode\nPembayaran}
    PayMethod -->|Tunai| CalcChange[Hitung Kembalian]
    PayMethod -->|QRIS/Transfer| RefNo[Input No. Referensi]
    
    CalcChange --> FinalizeOrder
    RefNo --> FinalizeOrder
    FinalizeOrder[✅ Order Selesai\nIsPaid: True\nStatus: Selesai] --> SendReceipt[Kirim Struk\nvia WhatsApp]
    SendReceipt --> TableFree[Update Meja\nStatus: Kosong]
    TableFree --> PosScreen

    style Start fill:#4F46E5,color:#fff
    style FinalizeOrder fill:#059669,color:#fff
    style StockError fill:#DC2626,color:#fff
```

---

## 4. Alur Manajemen Stok (Inventory)

```mermaid
flowchart LR
    subgraph "📥 Penerimaan Barang"
        GR1[Buat Goods Receipt\nDraft]
        GR2[Isi Supplier &\nItem + Qty + Harga]
        GR3[Approve Receipt]
        GR4["✅ Ingredient.Stock\n+= Qty Diterima"]
        GR5[Tulis StockHistory\nType: IN]
        GR1 --> GR2 --> GR3 --> GR4 --> GR5
    end

    subgraph "📤 Pengeluaran Barang"
        GI1[Buat Goods Issue\nDraft]
        GI2[Pilih Kategori:\nWaste / Transfer]
        GI3[Approve Issue]
        GI4["Ingredient.Stock\n-= Qty Keluar"]
        GI5[Tulis StockHistory\nType: WASTE/OUT]
        GI1 --> GI2 --> GI3 --> GI4 --> GI5
    end

    subgraph "🔄 Transfer Cabang"
        BO1[Cabang Buat\nBranch Order]
        BO2[Pusat Approve\n& Set Qty]
        BO3[Buat Goods Receipt\ndi Cabang Penerima]
        BO4[Stok Cabang\nBertambah]
        BO1 --> BO2 --> BO3 --> BO4
    end

    subgraph "⚠️ Monitoring"
        MON1[Cek StockHistory\nGET /api/stock/history]
        MON2{Stok < MinStock?}
        MON3[Alert/Notifikasi\nAdmin]
        MON1 --> MON2 -->|Ya| MON3
    end
```

---

## 5. Alur Void / Pembatalan Transaksi

```mermaid
flowchart TD
    A[👤 Kasir Pilih Order\nyang Ingin Dibatalkan] --> B{Order Sudah\nDibayar?}
    
    B -->|Belum Bayar| C[POST /api/orders/:id/void\nInput Alasan Void]
    B -->|Sudah Bayar| D[❌ Tidak Bisa Void\nHarus Manual Refund]

    C --> E{Tipe POS?}
    E -->|Retail/Fashion| F[Kembalikan Menu.Stock\n+= Qty Item]
    E -->|Resto/Jasa| G{Ada Resep\nIngredient?}
    G -->|Ya| H[Kembalikan Ingredient.Stock\n+ StockHistory Type: VOID]
    G -->|Tidak| I[Tidak Ada Stock\nyang Dikembalikan]
    
    F --> J[Status Order: Batal]
    H --> J
    I --> J
    J --> K[Meja Dibebaskan\n(Jika Resto)]
    
    style D fill:#DC2626,color:#fff
    style J fill:#6B7280,color:#fff
```

---

## 6. Alur Notifikasi WhatsApp (Qontak)

```mermaid
sequenceDiagram
    participant System as ⚙️ Backend
    participant Qontak as 💬 Qontak API
    participant Customer as 👤 Customer WA

    System->>System: Event Trigger\n(Aktivasi Akun / Order Selesai)
    System->>Qontak: POST /v1/send_message\n(phone, message, channel_id)
    Qontak-->>System: HTTP 200 OK\n(message_id)
    Qontak->>Customer: Kirim WA:\n"Selamat! Akun Anda aktif...\nUsername: xxx\nPassword: xxx"
    System->>System: Tulis WALog\n(status: Success/Failed)
```

---

*Terakhir diperbarui: Juni 2026 | Tim NFM Tech*
