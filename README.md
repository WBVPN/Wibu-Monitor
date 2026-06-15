# 🦊 Wibu Monitor - Multi VPS Centered Dashboard

Sistem monitoring performa dan traffic server VPN terpusat (Master-Node) berbasis HTTP API. Menggabungkan laporan banyak VPS ke dalam satu pesan Telegram yang sama secara realtime otomatis setiap 60 detik.

---

## 🔒 Sistem Keamanan (IP Authorization)
Script ini dilindungi oleh fitur **Auth IP**. Pastikan IP Publik VPS Master maupun Node sudah terdaftar di dalam file `ip_allowed.txt` sebelum melakukan instalasi. Jika IP belum terdaftar, instalasi akan otomatis dibatalkan oleh sistem.

---

## 👑 1. Panduan Instalasi di VPS MASTER (Pusat)
VPS Master adalah VPS utama yang bertugas membuka API Server untuk menerima data dari VPS Node, serta mengolahnya untuk dikirimkan ke Channel/Grup Telegram.

Jalankan perintah ini di **VPS MASTER** kamu:
```bash
wget -O /root/wibu_master.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh) && chmod +x /root/wibu_master.sh && /root/wibu_master.sh
