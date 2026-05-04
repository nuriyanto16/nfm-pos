#!/bin/bash

# Script Deploy Otomatis POS Resto
echo "🚀 Memulai proses update dan deploy..."

# 1. Tarik kode terbaru dari Git
echo "📥 Menarik kode terbaru dari Git..."
git pull origin main

# 2. Rebuild dan jalankan container
echo "🏗️ Membangun ulang container..."
docker-compose up -d --build

# 3. Bersihkan image yang tidak terpakai (dangling images)
echo "🧹 Membersihkan resource lama..."
docker image prune -f

echo "✅ Deploy selesai! Semua service berjalan smooth."
docker-compose ps
