# 🦊 Wibu Monitor - Auto Deploy Dashboard

Sistem monitoring performa server VPN terpusat (Master-Node) berbasis API. 
Sangat praktis! Script ini sudah dilengkapi fitur **Auto-Cronjob, Auto-Domain Detection, dan Auto-Open Firewall Port 5000**.

---

### 👑 1. Instalasi di VPS MASTER (Pusat)
Jalankan satu baris perintah ini di VPS Master Anda. (Script akan otomatis membuka firewall dan memasang jadwal cron).

```bash
wget -O /root/wibu_master.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh) && chmod +x /root/wibu_master.sh && /root/wibu_master.sh
```

---

### 📡 2. Instalasi di VPS NODE (Cabang Ke-2, 3, dst)
Jalankan satu baris perintah ini di VPS Node Anda. Ganti `IP_MASTER` dengan IP VPS Master Anda, dan `"NAMA SERVER"` dengan nama VPS cabang Anda.

```bash
wget -O /root/wibu_node.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh) && chmod +x /root/wibu_node.sh && /root/wibu_node.sh IP_MASTER "NAMA SERVER"
```

*(Catatan: Jika server Node belum memiliki catatan domain, script akan otomatis menghentikan proses sejenak untuk meminta Anda mengetikkan domain di terminal).*

---

### 🔒 Syarat Keamanan:
Pastikan IP Publik dari VPS Master maupun semua VPS Node sudah didaftarkan ke dalam file `ip_allowed.txt` sebelum instalasi dilakukan.

Jalankan perintah berikut di **VPS MASTER** Anda:
```bash
wget -O /root/wibu_master.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/master.sh) && chmod +x /root/wibu_master.sh && /root/wibu_master.sh


⏱️ Otomatisasi Cron Master
Agar data performa server diperbarui otomatis di Telegram setiap menit, masukkan ke crontab dengan perintah ini:

(crontab -l 2>/dev/null; echo "* * * * * /root/wibu_master.sh") | crontab -

📡 2. Panduan Instalasi di VPS NODE (Cabang / VPS Ke-2, Ke-3, dst)
Untuk VPS Node, instalasi dilakukan secara instan tanpa perlu membuka teks editor (nano/vi). Anda cukup memasukkan IP Master dan Nama Server sebagai parameter langsung saat mengeksekusi script.
Jalankan perintah pengunduhan ini di VPS NODE Anda:


wget -O /root/wibu_node.sh [https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh](https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/node.sh) && chmod +x /root/wibu_node.sh

🚀 Cara Menjalankan Eksekusi Node
Cara A (Metode Tembak Parameter - Sangat Direkomendasikan):
Format perintah: /root/wibu_node.sh [IP_MASTER] "[NAMA_NODE]"
(Silakan ganti 103.253.245.205 dengan IP asli Master Anda, dan "BANSOS SG" dengan nama server cabang tersebut).

⏱️ Otomatisasi Cron Node
Agar VPS Node rutin menyetorkan data performanya ke API Master setiap 60 detik, masukkan perintah otomatisasi ini ke crontab:

(crontab -l 2>/dev/null; echo '* * * * * /root/wibu_node.sh 103.253.245.205 "BANSOS SG"') | crontab -

🌐 3. Troubleshooting & Solusi Kendala Kecil
🅰️ Nama Domain Node Terbaca Sebagai ubuntu
Jika setelah instalasi selesai, bagian nama Domain pada VPS Node terbaca sebagai ubuntu atau belum.ada.domain.com, itu karena sistem tidak menemukan catatan domain di config bawaan.
Solusinya: Jalankan perintah ini di VPS Node tersebut untuk menanamkan domain aslinya secara paksa ke dalam memori sistem:
mkdir -p /etc/xray && echo "domain-asli-vps-anda.com" | tee /etc/xray/domain /root/domain > /dev/null


Setelah di-enter, tunggu 60 detik maka tulisan di Telegram akan berubah dengan sendirinya menjadi nama domain yang benar lengkap dengan sensor masking (domain-asli**.***.**).
🅱️ Proses Curl di VPS Node Mengalami Macet (Hang)
Jika saat menjalankan script node terminal berhenti lama tanpa respon, hal itu dikarenakan Port 5000 pada VPS Master ditutup oleh Firewall eksternal (Web Cloud Provider).
Solusinya: Masuk ke akun website tempat Anda membeli VPS Master (misal: DigitalOcean, AWS, Alibaba Cloud, Linode). Masuk ke menu Security Group / Firewall, lalu buat aturan baru (Add Inbound Rule):
Protocol: TCP
Port Range: 5000
Source / IP: 0.0.0.0/0 (Supaya bisa menerima setoran data dari VPS Node manapun).
