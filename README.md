# 🦊 Wibu Monitor - Auto Deploy Dashboard

Sistem monitoring performa server VPN terpusat (Master-Node) berbasis API. 
Sangat praktis! Script ini sudah dilengkapi fitur **Auto-Config Telegram, Auto-Cronjob, Auto-Domain Detection, dan Auto-Open Firewall Port 5000**.

---

### 👑 1. Instalasi di VPS MASTER (Pusat)
Jalankan satu baris perintah ini di VPS Master Anda. 

```bash
wget -O /root/wibu_master.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh) && chmod +x /root/wibu_master.sh && /root/wibu_master.sh
```
*(Catatan: Saat pertama kali dijalankan, script akan meminta Anda memasukkan **Bot Token** dan **Chat ID Telegram**. Setelah diisi, jadwal cron dan firewall akan terpasang otomatis).*

---

### 📡 2. Instalasi di VPS NODE (Cabang Ke-2, 3, dst)
Jalankan satu baris perintah ini di VPS Node Anda. Ganti `IP_MASTER` dengan IP VPS Master Anda, dan `"NAMA SERVER"` dengan nama VPS cabang Anda.

```bash
wget -O /root/wibu_node.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh) && chmod +x /root/wibu_node.sh && /root/wibu_node.sh IP_MASTER "NAMA SERVER"
```
*(Catatan: Jika server Node belum memiliki catatan domain, script akan meminta Anda mengetikkan domain di terminal sebelum menyelesaikan instalasi).*

---

### 🔒 Syarat Keamanan:
Pastikan IP Publik dari VPS Master maupun semua VPS Node sudah didaftarkan ke dalam file `ip_allowed.txt` sebelum instalasi dilakukan.

```bash
wget -O /root/wibu_node.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh) && chmod +x /root/wibu_node.sh && /root/wibu_node.sh IP_MASTER "NAMA SERVER"
```

*(Catatan: Jika server Node belum memiliki catatan domain, script akan otomatis menghentikan proses sejenak untuk meminta Anda mengetikkan domain di terminal).*

---

### 🔒 Syarat Keamanan:
Pastikan IP Publik dari VPS Master maupun semua VPS Node sudah didaftarkan ke dalam file `ip_allowed.txt` sebelum instalasi dilakukan.
