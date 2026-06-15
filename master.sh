#!/bin/bash

# ==========================================
# 🦊 WIBU MONITOR - MASTER SCRIPT (PREMIUM LAYOUT)
# ==========================================

# 1. VALIDASI IP (SATPAM)
URL_IZIN_IP="https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/ip_allowed.txt"
IP_SEKARANG=$(curl -s ifconfig.me)
DAFTAR_IP=$(curl -s "$URL_IZIN_IP")

if ! echo "$DAFTAR_IP" | grep -q -w "$IP_SEKARANG"; then
    echo "❌ ERROR: IP ($IP_SEKARANG) Tidak Terdaftar di GitHub!"
    exit 1
fi

# 2. SETUP BOT & NAMA MASTER
CONF_FILE="/root/.wibu_bot.conf"
if [ ! -f "$CONF_FILE" ]; then
    echo "=== SETUP MASTER MONITORING ==="
    read -p "Masukkan Bot Token : " INP_TOKEN
    read -p "Masukkan Chat ID   : " INP_CHATID
    read -p "Beri Nama VPS Master ini (misal: MASTER): " INP_NAME
    echo "BOT_TOKEN=\"$INP_TOKEN\"" > "$CONF_FILE"
    echo "CHAT_ID=\"$INP_CHATID\"" >> "$CONF_FILE"
    echo "MASTER_NAME=\"$INP_NAME\"" >> "$CONF_FILE"
fi
source "$CONF_FILE"
MSG_ID_FILE="/root/.wibu_msg_id"

# 3. SETUP API SERVER (PYTHON FLASK)
apt update -y &> /dev/null
apt install python3 python3-flask vnstat -y &> /dev/null

cat << 'EOF' > /root/api_server.py
from flask import Flask, request
app = Flask(__name__)

def get_allowed_ips():
    try:
        with open("/root/ip_allowed.txt", "r") as f:
            return [line.strip() for line in f if line.strip()]
    except:
        return []

@app.route('/api/report', methods=['POST'])
def report():
    if request.remote_addr not in get_allowed_ips():
        return "Forbidden", 403
    vps_name = request.form.get('name', 'unknown')
    vps_data = request.form.get('data', '')
    if vps_data:
        with open(f"/root/node_{vps_name}.txt", "w") as f:
            f.write(vps_data)
        return "OK", 200
    return "No Data", 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

pkill -f api_server.py &> /dev/null
nohup python3 /root/api_server.py > /dev/null 2>&1 &

# 4. GATHER DATA VPS MASTER
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || hostname -f)
IP_MASKED=$(echo "$IP_SEKARANG" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

GEO_DATA=$(curl -s http://ip-api.com/json/$IP_SEKARANG)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Jakarta"

UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
UPTIME_FMT=$(printf "%02d Jam, %02d Menit" $(awk "BEGIN {print int($UPTIME_RAW/3600)}") $(awk "BEGIN {print int(($UPTIME_RAW%3600)/60)}"))

SPEED_TEST=$(vnstat -tr 2 -i $INTERFACE 2>/dev/null)
RX=$(echo "$SPEED_TEST" | grep "rx" | awk '{print $2}')
TX=$(echo "$SPEED_TEST" | grep "tx" | awk '{print $2}')

BW_TODAY=$(vnstat -i $INTERFACE --oneline 2>/dev/null | awk -F';' '{print $6}')
BW_MONTH=$(vnstat -i $INTERFACE --oneline 2>/dev/null | awk -F';' '{print $11}')

STATUS=$(pgrep -x "xray" > /dev/null && echo "🟢 <b>ACTIVE</b>" || echo "🔴 <b>CRITICAL</b>")

TEXT="🦊 <b>WIBU SERVER REAL MONITORING</b> 🦊
════════════════════════════
👑 <b>SERVER : ${MASTER_NAME^^}</b>
 ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> $CITY (Auto)
 ┣ ⏳ <b>Uptime :</b> $UPTIME_FMT
 ┣ 🚀 <b>Speed  :</b> <code>$RX ↓ / $TX ↑ Mbps</code>
 ┣ 📊 <b>Traffic :</b> Hari Ini: $BW_TODAY | Bulan: $BW_MONTH
 ┗ 🛡️ <b>Status :</b> $STATUS"

# 5. AUTO-CLEANUP & GABUNGKAN DATA (DURASI 5 MENIT)
CURRENT_TIME=$(date +%s)
for file in /root/node_*.txt; do
    if [ -f "$file" ]; then
        FILE_TIME=$(stat -c %Y "$file")
        if [ $((CURRENT_TIME - FILE_TIME)) -gt 300 ]; then
            rm "$file"
        else
            NODE_NAME=$(basename "$file" .txt | sed 's/node_//')
            TEXT="$TEXT

────────────────────────────
👑 <b>SERVER : ${NODE_NAME^^}</b>
$(cat "$file")"
        fi
    fi
done

TEXT="$TEXT
════════════════════════════
⏱️ <b>Sinkronisasi :</b> <i>$(date '+%d %b %Y, %H:%M:%S') WIB</i>
🌸 <b>Data diperbarui otomatis setiap 60 detik.</b>"

# 6. KIRIM / UPDATE TELEGRAM
if [ -f "$MSG_ID_FILE" ]; then
    MSG_ID=$(cat "$MSG_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/editMessageText" \
        -d chat_id="$CHAT_ID" \
        -d message_id="$MSG_ID" \
        --data-urlencode "text=$TEXT" \
        -d parse_mode="HTML" > /dev/null
else
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        --data-urlencode "text=$TEXT" \
        -d parse_mode="HTML")
    MSG_ID=$(echo "$RESPONSE" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)
    if [[ "$MSG_ID" =~ ^[0-9]+$ ]]; then
        echo "$MSG_ID" > "$MSG_ID_FILE"
    fi
fi

# 7. CRONJOB
if ! crontab -l 2>/dev/null | grep -q "wibu_master.sh"; then
    (crontab -l 2>/dev/null; echo "* * * * * /root/wibu_master.sh") | crontab -
fi
