# 📚 Dokumentasi NFM POS — Daftar Isi

Selamat datang di folder dokumentasi sistem **NFM POS** — platform SaaS Point-of-Sale multi-tipe yang mendukung Resto, Retail, Fashion, dan Jasa.

---

## 📂 Daftar File Dokumentasi

| File | Keterangan |
|------|------------|
| [👑 SUPERUSER_GUIDE.md](./SUPERUSER_GUIDE.md) | **Panduan lengkap role Super User** — alur pendaftaran, pembayaran, aktivasi tenant, Telegram bot |
| [01_technology_stack.md](./01_technology_stack.md) | Tumpukan teknologi (Technology Stack), dependensi, dan arsitektur komponen |
| [02_flow_diagram.md](./02_flow_diagram.md) | Diagram alur sistem, registrasi, transaksi, dan integrasi |
| [03_role_process.md](./03_role_process.md) | Diagram proses per Role pengguna (Super User, Owner, Kasir) |
| [04_api_endpoints.md](./04_api_endpoints.md) | Daftar lengkap semua endpoint API beserta parameter dan respons |
| [05_database_schema.md](./05_database_schema.md) | Skema database, ERD relasi tabel, dan penjelasan field penting |
| [06_qontak_integration.md](./06_qontak_integration.md) | Panduan integrasi Qontak Omnichannel API (WhatsApp) |
| [dokumentasi_sistem.md](./dokumentasi_sistem.md) | Dokumen ringkasan sistem (generated) |

---

## 🚀 Quick Start

```bash
# Clone repository
git clone <repo-url>

# Jalankan dengan Docker Compose
docker-compose up -d

# Atau jalankan manual
# Backend
cd backend && go run ./cmd/api/main.go

# Frontend  
cd frontend && flutter run -d chrome

# Landing Page
cd landing-page && npm run dev
```

---

## 📞 Kontak & Support

Untuk pertanyaan atau laporan bug, hubungi tim NFM Tech melalui channel Telegram yang tersedia.
