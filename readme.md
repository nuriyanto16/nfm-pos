# POS Resto - Dokumentasi Operasional

Dokumentasi ini berisi panduan teknis untuk menjalankan, mengonfigurasi, dan melakukan deployment pada project POS Resto.

## 1. Cara Menjalankan Service

### Backend (Golang)
Backend bertanggung jawab untuk menyediakan API dan mengelola database.
1. Buka terminal dan masuk ke folder `backend`.
2. Pastikan file `.env` sudah dikonfigurasi dengan benar (Database & Port).
3. Jalankan perintah:
   ```powershell
   go run cmd/api/main.go
   ```
   *Atau jika ingin menjalankan file executable:* `./main.exe` (setelah melakukan `go build`).

### Frontend (Flutter)
Frontend adalah aplikasi multi-platform (Web & Mobile).
1. Buka terminal dan masuk ke folder `frontend`.
2. Ambil dependensi terbaru:
   ```powershell
   flutter pub get
   ```
3. Untuk menjalankan di **Chrome**:
   ```powershell
   flutter run -d chrome
   ```
4. Untuk menjalankan di **Device/Emulator Android**:
   ```powershell
   flutter run
   ```

---

## 2. Konfigurasi Dinamis (Otomatis)

Agar Anda tidak perlu mengubah IP secara manual setiap kali jaringan berubah, gunakan script otomatis:

1. Buka PowerShell.
2. Jalankan script di root folder:
   ```powershell
   ./update_ip.ps1
   ```
3. Script ini akan mendeteksi IP laptop Anda dan memperbarui file `frontend/.env` secara otomatis.

---

## 3. Akses dari Luar Jaringan (Tunneling)

Jika Anda ingin aplikasi dapat diakses dari internet (luar WiFi yang sama), Anda bisa menggunakan **Localtunnel** atau **Ngrok**:

1. Install Localtunnel: `npm install -g localtunnel`
2. Jalankan Tunnel untuk Backend: `lt --port 8080`
3. Salin URL yang diberikan (misal: `https://xyz.loca.lt`) dan masukkan ke `frontend/.env`:
   ```env
   BASE_URL=https://xyz.loca.lt/api/
   ```

---

## 4. Cara Build & Deploy APK

Untuk membuat file installer Android (.apk):

1. Masuk ke folder `frontend`.
2. **PENTING:** Ubah `BASE_URL` di `frontend/.env` ke IP Local komputer Anda (jangan gunakan `localhost`).
3. Jalankan perintah build:
   ```powershell
   flutter build apk --release
   ```
4. Jika build selesai, file APK dapat diambil di:
   `frontend\build\app\outputs\flutter-apk\app-release.apk`

> **Tips Troubleshooting Windows:**
> Jika build gagal karena error "different roots" pada Kotlin, pastikan file `frontend/android/gradle.properties` berisi:
> `kotlin.incremental=false`

---

## 5. Cara Menjalankan di Chrome

Untuk menjalankan versi web:
1. Pastikan folder aktif adalah `frontend`.
2. Jalankan perintah:
   ```powershell
   flutter run -d chrome
   ```
3. Secara default, Flutter akan memilih port acak. Untuk port tetap (misal 8081):
   ```powershell
   flutter run -d chrome --web-port 8081
   ```

---

## 6. Cara Redeploy (Update Aplikasi)

Setiap kali ada perubahan kode (Frontend atau Backend), ikuti langkah berikut:

### Redeploy Backend
1. Matikan service yang sedang jalan (Ctrl+C).
2. Jalankan kembali `go run cmd/api/main.go`.

### Redeploy Frontend / Refresh APK
1. Matikan proses flutter.
2. Bersihkan build lama (sangat disarankan):
   ```powershell
   flutter clean
   ```
3. Ambil dependensi kembali:
   ```powershell
   flutter pub get
   ```
4. Lakukan rebuild APK (langkah 3) atau jalankan ulang di Chrome (langkah 4).

---

## 7. Deployment Docker (VM Production)

Untuk melakukan deployment ke Production VM (misal: `nfmtech.my.id`), gunakan Docker Compose:

1. Pastikan Docker & Docker Compose sudah terinstall di VM.
2. Konfigurasi file `.env` di root folder:
   ```env
   # Domain Production
   LANDING_API_URL=https://product.nfmtech.my.id/api
   
   # Konfigurasi Internal (Jangan diubah)
   CHATBOT_URL=http://openclaw:5000
   ```
3. Jalankan perintah deployment:
   ```bash
   docker-compose up --build -d
   ```

### Struktur Port di VM:
- **Landing Page**: Port 3000 (`https://nfmtech.my.id`)
- **Dashboard Web**: Port 8081 (`https://product.nfmtech.my.id`)
- **Backend API**: Port 8080 (`https://product.nfmtech.my.id/api`)
- **Chatbot Service**: Port 5000 (Internal)

---
*Dibuat oleh Assistant AI untuk POS Resto Project - 2026*
