# 🦊 Wibu Monitor - Multi VPS Centered Dashboard

Sistem monitoring performa, spesifikasi, dan traffic data server VPN terpusat (Master-Node) berbasis HTTP API Server. Sistem ini mengintegrasikan laporan dari banyak VPS (Multi-Server) ke dalam **satu pesan Telegram yang sama** secara real-time dan diperbarui otomatis setiap 60 detik.

---

## 🔒 Sistem Keamanan (IP Authorization)
Script ini dilindungi oleh fitur **Auth IP Security**. Pastikan IP Publik dari VPS Master maupun semua VPS Node sudah didaftarkan terlebih dahulu ke dalam file `ip_allowed.txt` di repository ini. Jika IP tidak terdaftar, sistem keamanan akan otomatis membatalkan proses instalasi demi melindungi privasi server Anda.

---

## 👑 1. Panduan Instalasi di VPS MASTER (Pusat)
VPS Master adalah server utama yang bertugas membuka API Server pada Port `5000` untuk menerima setoran data dari seluruh VPS Node, mengolahnya, lalu mengirim/mengedit pesan ke Channel atau Grup Telegram. Script ini sudah dilengkapi pencari jalur otomatis untuk membuka firewall sistem.

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
