#!/bin/bash

# ==========================================
# 1. SATPAM - VALIDASI IZIN IP VIA GITHUB
# ==========================================
URL_IZIN_IP="https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/ip_allowed.txt"
IP_SEKARANG=$(curl -s ifconfig.me)
DAFTAR_IP=$(curl -s "$URL_IZIN_IP")

if ! echo "$DAFTAR_IP" | grep -q -w "$IP_SEKARANG"; then
    echo "=========================================="
    echo "❌ ERROR: AKSES DITOLAK!"
    echo "VPS IP ($IP_SEKARANG) Belum Terdaftar."
    echo "Silakan Hubungi Admin."
    echo "=========================================="
    exit 1
fi

# ==========================================
# 2. KONFIGURASI NODE (OTOMATIS VIA ARGUMEN)
# ==========================================
# Cara pakai: ./wibu_node.sh [IP_MASTER] [NAMA_NODE]
IP_MASTER="$1"
NODE_NAME="$2"

# Jika user lupa memasukkan parameter, script akan bertanya otomatis
if [ -z "$IP_MASTER" ] || [ -z "$NODE_NAME" ]; then
    echo "=== KONFIGURASI WIBU NODE ==="
    read -p "Masukkan IP VPS Master: " IP_MASTER
    read -p "Masukkan Nama Node (misal: SG-VIP): " NODE_NAME
fi

MASTER_API_URL="http://${IP_MASTER}:5000/api/report"

# ==========================================
# 3. AMBIL DATA NODE
# ==========================================
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)

if [ -f /etc/xray/domain ]; then DOMAIN=$(cat /etc/xray/domain); elif [ -f /root/domain ]; then DOMAIN=$(cat /root/domain); else DOMAIN=$(hostname -f); fi
[ -z "$DOMAIN" ] && DOMAIN="belum.ada.domain.com"

# SENSOR DOMAIN & IP
IP_MASKED=$(echo "$IP_SEKARANG" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

GEO_DATA=$(curl -s http://ip-api.com/json/$IP_SEKARANG)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Singapore"

UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
UP_H=$(awk "BEGIN {print int($UPTIME_RAW/3600)}")
UP_M=$(awk "BEGIN {print int(($UPTIME_RAW%3600)/60)}")
UPTIME_FMT=$(printf "%02d Jam, %02d Menit" $UP_H $UP_M)

SPEED_TEST=$(vnstat -tr 2 -i $INTERFACE)
RX_SPEED=$(echo "$SPEED_TEST" | grep "rx" | awk '{print $2}')
TX_SPEED=$(echo "$SPEED_TEST" | grep "tx" | awk '{print $2}')

BW_TODAY=$(vnstat -i $INTERFACE --oneline | awk -F';' '{print $6}')
BW_MONTH=$(vnstat -i $INTERFACE --oneline | awk -F';' '{print $14}')
[ -z "$BW_TODAY" ] && BW_TODAY="0.00 MB"
[ -z "$BW_MONTH" ] && BW_MONTH="0.00 MB"

if pgrep -x "xray" > /dev/null || pgrep -x "haproxy" > /dev/null; then STATUS="🟢 <b>ACTIVE</b>"; else STATUS="🔴 <b>CRITICAL ERROR</b>"; fi

# ==========================================
# 4. FORMAT & KIRIM KE MASTER
# ==========================================
DATA_TEXT=" ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> <code>$CITY (Auto)</code>
 ┣ ⏳ <b>Uptime :</b> <code>$UPTIME_FMT</code>
 ┣ 🚀 <b>Speed  :</b> <code>$RX_SPEED ↓ / $TX_SPEED ↑ Mbps</code>
 ┣ 📊 <b>Traffic:</b> <code>Hari Ini: $BW_TODAY | Bulan: $BW_MONTH</code>
 ┗ 🛡️ <b>Status :</b> $STATUS"

curl -s -X POST "$MASTER_API_URL" -d "name=$NODE_NAME" --data-urlencode "data=$DATA_TEXT" > /dev/null

GEO_DATA=$(curl -s http://ip-api.com/json/$IP_SEKARANG)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Singapore"

UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
UP_H=$(awk "BEGIN {print int($UPTIME_RAW/3600)}")
UP_M=$(awk "BEGIN {print int(($UPTIME_RAW%3600)/60)}")
UPTIME_FMT=$(printf "%02d Jam, %02d Menit" $UP_H $UP_M)

SPEED_TEST=$(vnstat -tr 2 -i $INTERFACE)
RX_SPEED=$(echo "$SPEED_TEST" | grep "rx" | awk '{print $2}')
TX_SPEED=$(echo "$SPEED_TEST" | grep "tx" | awk '{print $2}')

BW_TODAY=$(vnstat -i $INTERFACE --oneline | awk -F';' '{print $6}')
BW_MONTH=$(vnstat -i $INTERFACE --oneline | awk -F';' '{print $14}')
[ -z "$BW_TODAY" ] && BW_TODAY="0.00 MB"
[ -z "$BW_MONTH" ] && BW_MONTH="0.00 MB"

if pgrep -x "xray" > /dev/null || pgrep -x "haproxy" > /dev/null; then STATUS="🟢 <b>ACTIVE</b>"; else STATUS="🔴 <b>CRITICAL ERROR</b>"; fi

# ==========================================
# 4. FORMAT & KIRIM KE MASTER
# ==========================================
DATA_TEXT=" ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> <code>$CITY (Auto)</code>
 ┣ ⏳ <b>Uptime :</b> <code>$UPTIME_FMT</code>
 ┣ 🚀 <b>Speed  :</b> <code>$RX_SPEED ↓ / $TX_SPEED ↑ Mbps</code>
 ┣ 📊 <b>Traffic:</b> <code>Hari Ini: $BW_TODAY | Bulan: $BW_MONTH</code>
 ┗ 🛡️ <b>Status :</b> $STATUS"

curl -s -X POST "$MASTER_API_URL" -d "name=$NODE_NAME" --data-urlencode "data=$DATA_TEXT" > /dev/null
