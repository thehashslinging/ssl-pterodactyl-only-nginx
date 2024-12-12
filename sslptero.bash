#!/bin/bash

# Memastikan skrip dijalankan dengan hak akses root
if [ "$EUID" -ne 0 ]; then
  echo "Harap jalankan skrip ini sebagai root!"
  exit 1
fi

# Meminta input domain dari pengguna
echo "Masukkan domain atau subdomain untuk panel Pterodactyl (contoh: panel.example.com):"
read -r DOMAIN

# Memastikan domain tidak kosong
if [ -z "$DOMAIN" ]; then
  echo "Domain tidak boleh kosong. Skrip dihentikan."
  exit 1
fi

# Memastikan Certbot terinstal
if ! command -v certbot &> /dev/null; then
  echo "Certbot tidak ditemukan. Menginstal Certbot..."
  apt update && apt install -y certbot
fi

# Memeriksa apakah Nginx digunakan
if ! command -v nginx &> /dev/null; then
  echo "Nginx tidak ditemukan di server ini. Skrip dihentikan."
  exit 1
fi

# Menjalankan Certbot untuk Nginx
echo "Konfigurasi SSL untuk Nginx..."
certbot --nginx -d "$DOMAIN"

# Menambahkan cronjob untuk pembaruan otomatis SSL
if ! crontab -l | grep -q "certbot renew"; then
  echo "Menambahkan cronjob untuk pembaruan SSL otomatis..."
  (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet") | crontab -
else
  echo "Cronjob untuk pembaruan SSL sudah ada."
fi

# Restart Nginx
systemctl restart nginx

# Informasi akhir
echo "Konfigurasi SSL selesai. Akses domain Anda di https://$DOMAIN"
