# POS Resto Modern API Documentation

Base URL: `http://localhost:8080/api`

## Authentication

### 1. Login
- **URL**: `/login`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "username": "admin",
    "password": "password123"
  }
  ```
- **Response** (200 OK):
  ```json
  {
    "token": "jwt_token_string",
    "user": {
      "id": 1,
      "username": "admin",
      "role": "Admin"
    }
  }
  ```

---

*Note: All endpoints below require the `Authorization` header:*
`Authorization: Bearer <jwt_token_string>`

## Menu & Categories

### 2. Get All Menus
- **URL**: `/menus`
- **Method**: `GET`
- **Response** (200 OK): List of menus with their assigned category.

### 3. Create Menu (Admin)
- **URL**: `/menus`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "category_id": 1,
    "name": "Sate Ayam",
    "price": 25000,
    "stock": 100
  }
  ```

### 4. Get Categories
- **URL**: `/categories`
- **Method**: `GET`

---

## Tables / Meja

### 5. Get All Tables
- **URL**: `/tables`
- **Method**: `GET`
- **Response** (200 OK): 
  ```json
  [
    {"id": 1, "table_number": "T1", "status": "Kosong"},
    {"id": 2, "table_number": "T2", "status": "Digunakan"}
  ]
  ```

### 6. Update Table Status
- **URL**: `/tables/:id/status`
- **Method**: `PUT`
- **Body**:
  ```json
  { "status": "Dipesan" } // Kosong, Dipesan, Digunakan
  ```

---

## Orders / Transaksi

### 7. Create Order
- **URL**: `/orders`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "table_id": 1, // Optional, null for take-away
    "customer_name": "John Doe",
    "notes": "Pedas manis",
    "items": [
      {
        "menu_id": 1,
        "quantity": 2
      }
    ]
  }
  ```

### 8. Get All Orders
- **URL**: `/orders`
- **Method**: `GET`

### 9. Update Order Status (Kitchen / Waiter)
- **URL**: `/orders/:id/status`
- **Method**: `PUT`
- **Body**:
  ```json
  { "status": "Proses" } // Pending, Proses, Selesai, Batal
  ```

### 10. Process Payment (Checkout)
- **URL**: `/orders/:id/pay`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "amount_paid": 50000,
    "payment_method": "Tunai" // Tunai, QRIS, E-Wallet
  }
  ```
