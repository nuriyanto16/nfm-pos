# Script untuk mengupdate IP Address secara otomatis di file .env
# Jalankan script ini setiap kali IP local laptop Anda berubah.

# 1. Mendapatkan IP Local (IPv4) - Prioritaskan adapter fisik (Wi-Fi/Ethernet)
$localIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -notlike "*Loopback*" -and 
    $_.InterfaceAlias -notlike "*vEthernet*" -and 
    $_.InterfaceAlias -notlike "*VMware*" -and 
    $_.InterfaceAlias -notlike "*Virtual*" -and
    $_.IPv4Address -notlike "169.254.*"
} | Select-Object -First 1).IPAddress

if (-not $localIp) {
    Write-Host "Gagal mendapatkan IP Local. Pastikan Anda terhubung ke jaringan." -ForegroundColor Red
    exit
}

Write-Host "IP Local Terdeteksi: $localIp" -ForegroundColor Cyan

# 2. Update frontend/.env
$frontendEnvPath = "frontend/.env"
if (Test-Path $frontendEnvPath) {
    $content = "BASE_URL=http://$($localIp):8080/api/`n"
    Set-Content -Path $frontendEnvPath -Value $content
    Write-Host "Berhasil update $frontendEnvPath" -ForegroundColor Green
} else {
    Write-Host "File $frontendEnvPath tidak ditemukan." -ForegroundColor Yellow
}

# 3. Update dokumentasi di readme.md (Opsional)
# Anda bisa menambahkan logika di sini jika ingin mengubah teks di readme secara otomatis.

Write-Host "Selesai! Silakan build ulang APK atau jalankan Chrome." -ForegroundColor Magenta
