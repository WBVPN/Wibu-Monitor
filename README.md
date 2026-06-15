# 🦊 WIBU MONITOR - Multi-Server Realtime Monitoring Bot Telegram

Script monitoring spesifikasi, performa, *speed*, *status service*, dan pemakaian *traffic/bandwidth* realtime untuk multi-server VPS (Master & Node) yang terintegrasi langsung dengan Bot Telegram.

---

## 📢 PENDAFTARAN IP WHITELIST
> ⚠️ **PENTING:** Script ini dilengkapi dengan sistem keamanan *IP Whitelist*. Agar VPS kamu bisa berjalan dan tidak terkena error `403 Forbidden`, jalankan pendaftaran IP terlebih dahulu.
> 
> 🆓 **Untuk pendaftaran IP Gratis, silakan hubungi:**
> * **Telegram:** [t.me/wibuvpn](https://t.me/wibuvpn)
> * **WhatsApp:** [087757315408](https://wa.me/6287757315408)

---

## 🚀 CARA PEMASANGAN (INSTALL)

### 1. Setup di VPS MASTER (Pusat Data)
VPS Master berfungsi sebagai server pusat yang menerima laporan dari semua VPS Node dan memperbarui pesan di Telegram.

Jalankan perintah ini di VPS Master kamu:
```bash
wget -O /root/wibu_master.sh https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh && chmod +x /root/wibu_master.sh && /root/wibu_master.sh
```
*Ikuti instruksi di layar untuk memasukkan **Bot Token**, **Chat ID Telegram**, dan **Nama Server Master**.*

### 2. Setup di VPS NODE (Cabang / Anggota)
Jalankan perintah ini di setiap VPS anak/cabang yang ingin kamu monitor:
```bash
wget -O /root/wibu_node.sh https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh && chmod +x /root/wibu_node.sh && /root/wibu_node.sh 103.253.245.205 "SG 1"
```
> 💡 *Contoh penggunaan:* `/root/wibu_node.sh 192.168.1.1 "SERVER 1"`

---

## 🗑️ CARA UNINSTALL (HAPUS BERSIH)

Jika kamu ingin menghapus total script monitoring ini dari VPS sampai bersih ke akarnya, silakan gunakan perintah di bawah ini sesuai jenis servernya:

### A. Uninstall dari VPS MASTER
Perintah ini akan menghentikan API Python Server, menghapus jadwal otomatis (*cronjob*), dan menghapus semua file konfigurasi secara permanen dari VPS Master:
```bash
pkill -f api_server.py; pkill -f wibu_; crontab -l | grep -v "wibu_" | crontab -; rm -f /root/wibu_master.sh /root/api_server.py /root/.wibu_bot.conf /root/.wibu_msg_id /root/node_*.txt /root/ip_allowed.txt
```

### B. Uninstall dari VPS NODE (Cabang)
Perintah ini akan menghentikan proses pengiriman data dan menghapus jadwal otomatis (*cronjob*) di VPS cabang:
```bash
pkill -f wibu_node.sh; crontab -l | grep -v "wibu_node.sh" | crontab -; rm -f /root/wibu_node.sh
```

---
🦊 **Developed by WBVPN Team**
