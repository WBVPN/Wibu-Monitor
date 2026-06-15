# 🦊 Wibu Monitor - Multi VPS Centered Dashboard

Sistem monitoring performa dan traffic server VPN terpusat (Master-Node) berbasis HTTP API Server. Menggabungkan laporan banyak VPS ke dalam satu pesan Telegram secara realtime otomatis setiap 60 detik.

---

## 🔒 Sistem Keamanan (IP Authorization)
Script ini dilindungi oleh sistem **Auth IP Security**. Pastikan IP Publik VPS Master maupun Node sudah didaftarkan terlebih dahulu ke dalam file `ip_allowed.txt` di repository ini. Jika IP tidak terdaftar, script akan otomatis menghentikan proses instalasi.

---

## 👑 1. Panduan Instalasi di VPS MASTER (Pusat)
Jalankan perintah berikut di **VPS MASTER** kamu untuk menginstal API Server dan pengirim Telegram:

```bash
wget -O /root/wibu_master.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh) && chmod +x /root/wibu_master.sh && /root/wibu_master.sh
