#!/bin/bash

# ==========================================
# 🦊 WIBU MONITOR - MASTER SCRIPT (V.FINAL)
# ==========================================

# 1. SATPAM - VALIDASI IZIN IP VIA GITHUB
URL_IZIN_IP="https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/refs/heads/main/ip_allowed.txt"
IP_SEKARANG=$(curl -s ifconfig.me)
DAFTAR_IP=$(curl -s "$URL_IZIN_IP")

if ! echo "$DAFTAR_IP" | grep -q -w "$IP_SEKARANG"; then
    echo "❌ ERROR: AKSES DITOLAK! IP ($IP_SEKARANG) tidak terdaftar di ip_allowed.txt"
    exit 1
fi

# 2. KONFIGURASI TELEGRAM (AUTO-CONFIG)
CONF_FILE="/root/.wibu_bot.conf"
if [ ! -f "$CONF_FILE" ]; then
    echo "=========================================="
    echo "🦊 SETUP TELEGRAM BOT MONITORING"
    echo "=========================================="
    read -p "✍️ Masukkan BOT TOKEN Anda : " INP_TOKEN
    read -p "✍️ Masukkan CHAT ID Anda   : " INP_CHATID
    echo "BOT_TOKEN=\"$INP_TOKEN\"" > "$CONF_FILE"
    echo "CHAT_ID=\"$INP_CHATID\"" >> "$CONF_FILE"
fi
source "$CONF_FILE"
MSG_ID_FILE="/root/.wibu_msg_id"

# 3. SETUP API SERVER & FIREWALL
iptables -I INPUT -p tcp --dport 5000 -j ACCEPT &> /dev/null
if command -v ufw &> /dev/null; then ufw allow 5000/tcp &> /dev/null; fi

if ! command -v python3 &> /dev/null; then apt update && apt install python3 -y; fi
if ! dpkg -s python3-flask &> /dev/null; then apt update && apt install python3-flask -y; fi

cat << 'EOF' > /root/api_server.py
from flask import Flask, request
app = Flask(__name__)

def get_allowed_ips():
    try:
        with open("/root/ip_allowed.txt", "r") as f:
            return [line.strip() for line in f if line.strip()]
    except: return []

@app.route('/api/report', methods=['POST'])
def report():
    if request.remote_addr not in get_allowed_ips(): return "Forbidden", 403
    vps_name = request.form.get('name', 'unknown')
    vps_data = request.form.get('data', '')
    if vps_data:
        with open(f"/root/node_{vps_name}.txt", "w") as f: f.write(vps_data)
        return "OK", 200
    return "No Data", 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

if ! pgrep -f "api_server.py" > /dev/null; then
    pkill -f api_server.py &> /dev/null
    nohup python3 /root/api_server.py > /dev/null 2>&1 &
fi

# 4. DATA MASTER (LOKAL)
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || hostname -f)
IP_MASKED=$(echo "$IP_SEKARANG" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')
GEO_DATA=$(curl -s http://ip-api.com/json/$IP_SEKARANG)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Jakarta"
UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
UPTIME_FMT=$(printf "%02d Jam, %02d Menit" $(awk "BEGIN {print int($UPTIME_RAW/3600)}") $(awk "BEGIN {print int(($UPTIME_RAW%3600)/60)}"))
SPEED_TEST=$(vnstat -tr 2 -i $INTERFACE)
RX_SPEED=$(echo "$SPEED_TEST" | grep "rx" | awk '{print $2}')
TX_SPEED=$(echo "$SPEED_TEST" | grep "tx" | awk '{print $2}')
BW_TODAY=$(vnstat -i $INTERFACE --oneline | awk -F';' '{print $6}')
STATUS=$(pgrep -x "xray" > /dev/null && echo "🟢 <b>ACTIVE</b>" || echo "🔴 <b>CRITICAL</b>")

# 5. GABUNGKAN DATA & AUTO-CLEANUP
TEXT="🦊 <b>WIBU SERVER REAL MONITORING</b> 🦊
════════════════════════════
👑 <b>SERVER : MASTER</b>
 ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🚀 <b>Speed  :</b> <code>$RX_SPEED ↓ / $TX_SPEED ↑ Mbps</code>
 ┣ 🛡️ <b>Status :</b> $STATUS"

CURRENT_TIME=$(date +%s)
for file in /root/node_*.txt; do
    if [ -f "$file" ]; then
        # Jika file > 120 detik, hapus (cleanup)
        if [ $((CURRENT_TIME - $(stat -c %Y "$file"))) -gt 120 ]; then
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
⏱️ <b>Update :</b> <i>$(date '+%d %b %Y, %H:%M:%S')</i>"

# 6. KIRIM / EDIT TELEGRAM
if [ -f "$MSG_ID_FILE" ]; then
    MSG_ID=$(cat "$MSG_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/editMessageText" -d chat_id="$CHAT_ID" -d message_id="$MSG_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML" > /dev/null
else
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML")
    MSG_ID=$(echo "$RESPONSE" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)
    [[ "$MSG_ID" =~ ^[0-9]+$ ]] && echo "$MSG_ID" > "$MSG_ID_FILE"
fi

# 7. AUTO-CRON
if ! crontab -l 2>/dev/null | grep -q "wibu_master.sh"; then
    (crontab -l 2>/dev/null; echo "* * * * * /root/wibu_master.sh") | crontab -
fi
source "$CONF_FILE"
MSG_ID_FILE="/root/.wibu_msg_id"

# ==========================================
# 3. SETUP API SERVER & BUKA PASSWALL/FIREWALL
# ==========================================
iptables -I INPUT -p tcp --dport 5000 -j ACCEPT &> /dev/null
if command -v ufw &> /dev/null; then ufw allow 5000/tcp &> /dev/null; fi

if ! command -v python3 &> /dev/null; then apt update && apt install python3 -y; fi
if ! dpkg -s python3-flask &> /dev/null; then apt update && apt install python3-flask -y; fi

cat << 'EOF' > /root/api_server.py
from flask import Flask, request
app = Flask(__name__)

@app.route('/api/report', methods=['POST'])
def report():
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

if ! pgrep -f "api_server.py" > /dev/null; then
    pkill -f api_server.py &> /dev/null
    nohup python3 /root/api_server.py > /dev/null 2>&1 &
fi

# ==========================================
# 4. AMBIL DATA VPS MASTER (DIRI SENDIRI)
# ==========================================
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
if [ -f /etc/xray/domain ]; then DOMAIN=$(cat /etc/xray/domain); elif [ -f /root/domain ]; then DOMAIN=$(cat /root/domain); else DOMAIN=$(hostname -f); fi
[ -z "$DOMAIN" ] && DOMAIN="belum.ada.domain.com"

IP_MASKED=$(echo "$IP_SEKARANG" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

GEO_DATA=$(curl -s http://ip-api.com/json/$IP_SEKARANG)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Jakarta"

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
# 5. GABUNGKAN DATA MASTER + SEMUA NODE
# ==========================================
TEXT="🦊 <b>WIBU SERVER REAL MONITORING</b> 🦊
════════════════════════════
👑 <b>SERVER : MASTER</b>
 ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> <code>$CITY (Auto)</code>
 ┣ ⏳ <b>Uptime :</b> <code>$UPTIME_FMT</code>
 ┣ 🚀 <b>Speed  :</b> <code>$RX_SPEED ↓ / $TX_SPEED ↑ Mbps</code>
 ┣ 📊 <b>Traffic:</b> <code>Hari Ini: $BW_TODAY | Bulan: $BW_MONTH</code>
 ┗ 🛡️ <b>Status :</b> $STATUS"

for file in /root/node_*.txt; do
    if [ -f "$file" ]; then
        NODE_NAME=$(basename "$file" .txt | sed 's/node_//')
        TEXT="$TEXT

────────────────────────────
👑 <b>SERVER : ${NODE_NAME^^}</b>
$(cat "$file")"
    fi
done

TEXT="$TEXT
════════════════════════════
⏱️ <b>Sinkronisasi :</b> <i>$(date '+%d %B %Y, %H:%M:%S WIB')</i>
🌸 <i>Data diperbarui otomatis setiap 60 detik.</i>"

# ==========================================
# 6. KIRIM / EDIT PESAN TELEGRAM
# ==========================================
if [ -f "$MSG_ID_FILE" ]; then
    MSG_ID=$(cat "$MSG_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/editMessageText" -d chat_id="$CHAT_ID" -d message_id="$MSG_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML" > /dev/null
else
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML")
    MSG_ID=$(echo "$RESPONSE" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)
    if [[ "$MSG_ID" =~ ^[0-9]+$ ]]; then echo "$MSG_ID" > "$MSG_ID_FILE"; fi
fi

# ==========================================
# 7. AUTO-INSTALL CRONJOB (JADWAL OTOMATIS)
# ==========================================
if ! crontab -l 2>/dev/null | grep -q "wibu_master.sh"; then
    (crontab -l 2>/dev/null; echo "* * * * * /root/wibu_master.sh") | crontab -
    echo -e "\n✅ Instalasi Selesai! Cronjob Master otomatis terpasang."
fi
app = Flask(__name__)

@app.route('/api/report', methods=['POST'])
def report():
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

if ! pgrep -f "api_server.py" > /dev/null; then
    pkill -f api_server.py &> /dev/null
    nohup python3 /root/api_server.py > /dev/null 2>&1 &
fi

# ==========================================
# 4. AMBIL DATA VPS MASTER (DIRI SENDIRI)
# ==========================================
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
if [ -f /etc/xray/domain ]; then DOMAIN=$(cat /etc/xray/domain); elif [ -f /root/domain ]; then DOMAIN=$(cat /root/domain); else DOMAIN=$(hostname -f); fi
[ -z "$DOMAIN" ] && DOMAIN="belum.ada.domain.com"

IP_MASKED=$(echo "$IP_SEKARANG" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

GEO_DATA=$(curl -s http://ip-api.com/json/$IP_SEKARANG)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Jakarta"

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
# 5. GABUNGKAN DATA MASTER + SEMUA NODE
# ==========================================
TEXT="🦊 <b>WIBU SERVER REAL MONITORING</b> 🦊
════════════════════════════
👑 <b>SERVER : MASTER</b>
 ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> <code>$CITY (Auto)</code>
 ┣ ⏳ <b>Uptime :</b> <code>$UPTIME_FMT</code>
 ┣ 🚀 <b>Speed  :</b> <code>$RX_SPEED ↓ / $TX_SPEED ↑ Mbps</code>
 ┣ 📊 <b>Traffic:</b> <code>Hari Ini: $BW_TODAY | Bulan: $BW_MONTH</code>
 ┗ 🛡️ <b>Status :</b> $STATUS"

for file in /root/node_*.txt; do
    if [ -f "$file" ]; then
        NODE_NAME=$(basename "$file" .txt | sed 's/node_//')
        TEXT="$TEXT

────────────────────────────
👑 <b>SERVER : ${NODE_NAME^^}</b>
$(cat "$file")"
    fi
done

TEXT="$TEXT
════════════════════════════
⏱️ <b>Sinkronisasi :</b> <i>$(date '+%d %B %Y, %H:%M:%S WIB')</i>
🌸 <i>Data diperbarui otomatis setiap 60 detik.</i>"

# ==========================================
# 6. KIRIM / EDIT PESAN TELEGRAM
# ==========================================
if [ -f "$MSG_ID_FILE" ]; then
    MSG_ID=$(cat "$MSG_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/editMessageText" -d chat_id="$CHAT_ID" -d message_id="$MSG_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML" > /dev/null
else
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML")
    MSG_ID=$(echo "$RESPONSE" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)
    if [[ "$MSG_ID" =~ ^[0-9]+$ ]]; then echo "$MSG_ID" > "$MSG_ID_FILE"; fi
fi

# ==========================================
# 7. AUTO-INSTALL CRONJOB (JADWAL OTOMATIS)
# ==========================================
if ! crontab -l 2>/dev/null | grep -q "wibu_master.sh"; then
    (crontab -l 2>/dev/null; echo "* * * * * /root/wibu_master.sh") | crontab -
    echo -e "\n✅ Instalasi Selesai! Cronjob Master otomatis terpasang."
fi
# Buat File Python API Penerima
cat << 'EOF' > /root/api_server.py
from flask import Flask, request

app = Flask(__name__)

@app.route('/api/report', methods=['POST'])
def report():
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

# Jalankan API Server di Background
if ! pgrep -f "api_server.py" > /dev/null; then
    pkill -f api_server.py &> /dev/null
    nohup python3 /root/api_server.py > /dev/null 2>&1 &
fi

# ==========================================
# 4. AMBIL DATA VPS MASTER (DIRI SENDIRI)
# ==========================================
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
if [ -f /etc/xray/domain ]; then DOMAIN=$(cat /etc/xray/domain); elif [ -f /root/domain ]; then DOMAIN=$(cat /root/domain); else DOMAIN=$(hostname -f); fi
[ -z "$DOMAIN" ] && DOMAIN="belum.ada.domain.com"

IP_MASKED=$(echo "$IP_SEKARANG" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

GEO_DATA=$(curl -s http://ip-api.com/json/$IP_SEKARANG)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Jakarta"

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
# 5. GABUNGKAN DATA MASTER + SEMUA NODE
# ==========================================
TEXT="🦊 <b>WIBU SERVER REAL MONITORING</b> 🦊
════════════════════════════
👑 <b>SERVER : MASTER</b>
 ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> <code>$CITY (Auto)</code>
 ┣ ⏳ <b>Uptime :</b> <code>$UPTIME_FMT</code>
 ┣ 🚀 <b>Speed  :</b> <code>$RX_SPEED ↓ / $TX_SPEED ↑ Mbps</code>
 ┣ 📊 <b>Traffic:</b> <code>Hari Ini: $BW_TODAY | Bulan: $BW_MONTH</code>
 ┗ 🛡️ <b>Status :</b> $STATUS"

for file in /root/node_*.txt; do
    if [ -f "$file" ]; then
        NODE_NAME=$(basename "$file" .txt | sed 's/node_//')
        TEXT="$TEXT

────────────────────────────
👑 <b>SERVER : ${NODE_NAME^^}</b>
$(cat "$file")"
    fi
done

TEXT="$TEXT
════════════════════════════
⏱️ <b>Sinkronisasi :</b> <i>$(date '+%d %B %Y, %H:%M:%S WIB')</i>
🌸 <i>Data diperbarui otomatis setiap 60 detik.</i>"

# ==========================================
# 6. KIRIM / EDIT PESAN TELEGRAM
# ==========================================
if [ -f "$MSG_ID_FILE" ]; then
    MSG_ID=$(cat "$MSG_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/editMessageText" -d chat_id="$CHAT_ID" -d message_id="$MSG_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML" > /dev/null
else
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML")
    MSG_ID=$(echo "$RESPONSE" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)
    if [[ "$MSG_ID" =~ ^[0-9]+$ ]]; then echo "$MSG_ID" > "$MSG_ID_FILE"; fi
fi
app = Flask(__name__)

@app.route('/api/report', methods=['POST'])
def report():
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

if ! pgrep -f "api_server.py" > /dev/null; then
    nohup python3 /root/api_server.py > /dev/null 2>&1 &
fi

# ==========================================
# 4. AMBIL DATA VPS MASTER (DIRI SENDIRI)
# ==========================================
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
if [ -f /etc/xray/domain ]; then DOMAIN=$(cat /etc/xray/domain); elif [ -f /root/domain ]; then DOMAIN=$(cat /root/domain); else DOMAIN=$(hostname -f); fi
[ -z "$DOMAIN" ] && DOMAIN="belum.ada.domain.com"

# SENSOR DOMAIN & IP
IP_MASKED=$(echo "$IP_SEKARANG" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

GEO_DATA=$(curl -s http://ip-api.com/json/$IP_SEKARANG)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Jakarta"

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
# 5. GABUNGKAN DATA MASTER + SEMUA NODE
# ==========================================
TEXT="🦊 <b>WIBU SERVER REAL MONITORING</b> 🦊
════════════════════════════
👑 <b>SERVER : MASTER</b>
 ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> <code>$CITY (Auto)</code>
 ┣ ⏳ <b>Uptime :</b> <code>$UPTIME_FMT</code>
 ┣ 🚀 <b>Speed  :</b> <code>$RX_SPEED ↓ / $TX_SPEED ↑ Mbps</code>
 ┣ 📊 <b>Traffic:</b> <code>Hari Ini: $BW_TODAY | Bulan: $BW_MONTH</code>
 ┗ 🛡️ <b>Status :</b> $STATUS"

for file in /root/node_*.txt; do
    if [ -f "$file" ]; then
        NODE_NAME=$(basename "$file" .txt | sed 's/node_//')
        TEXT="$TEXT

────────────────────────────
👑 <b>SERVER : ${NODE_NAME^^}</b>
$(cat "$file")"
    fi
done

TEXT="$TEXT
════════════════════════════
⏱️ <b>Sinkronisasi :</b> <i>$(date '+%d %B %Y, %H:%M:%S WIB')</i>
🌸 <i>Data diperbarui otomatis setiap 60 detik.</i>"

# ==========================================
# 6. KIRIM / EDIT PESAN TELEGRAM
# ==========================================
if [ -f "$MSG_ID_FILE" ]; then
    MSG_ID=$(cat "$MSG_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/editMessageText" -d chat_id="$CHAT_ID" -d message_id="$MSG_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML" > /dev/null
else
    RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id="$CHAT_ID" --data-urlencode "text=$TEXT" -d parse_mode="HTML")
    MSG_ID=$(echo "$RESPONSE" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)
    if [[ "$MSG_ID" =~ ^[0-9]+$ ]]; then echo "$MSG_ID" > "$MSG_ID_FILE"; fi
fi
