#!/bin/bash

# ==========================================
# 🦊 WIBU MONITOR - MASTER SCRIPT (FINAL PREMIUM)
# ==========================================

# 1. DETECT IP (For display only)
IP_SEKARANG=$(curl -s --connect-timeout 5 --max-time 10 ifconfig.me)
if [ -z "$IP_SEKARANG" ]; then
    IP_SEKARANG=$(curl -s --connect-timeout 5 --max-time 10 icanhazip.com)
fi
if [ -z "$IP_SEKARANG" ]; then
    echo "❌ ERROR: Cannot detect IP (network issue)"
    exit 1
fi

# 2. SETUP BOT & NAMA MASTER (atomic config write with API key)
CONF_FILE="/root/.wibu_bot.conf"
if [ ! -f "$CONF_FILE" ]; then
    if [ -t 0 ]; then
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║   🦊 WIBU MONITOR - MASTER SETUP      ║"
        echo "╚════════════════════════════════════════╝"
        echo ""
        read -p "Bot Token  : " INP_TOKEN
        read -p "Chat ID    : " INP_CHATID
        read -p "Server Name: " INP_NAME
        
        echo ""
        echo "⏳ Generating secure API key..."
        
        # Generate unique API key (32 char hex)
        API_KEY=$(openssl rand -hex 16)
        
        CONF_TEMP=$(mktemp)
        trap "rm -f $CONF_TEMP" EXIT
        echo "BOT_TOKEN=\"$INP_TOKEN\"" > "$CONF_TEMP"
        echo "CHAT_ID=\"$INP_CHATID\"" >> "$CONF_TEMP"
        echo "MASTER_NAME=\"$INP_NAME\"" >> "$CONF_TEMP"
        echo "API_KEY=\"$API_KEY\"" >> "$CONF_TEMP"
        mv "$CONF_TEMP" "$CONF_FILE"
        
        echo ""
        echo "✅ Setup Complete!"
        echo ""
        echo "╔════════════════════════════════════════╗"
        echo "║          CONFIGURATION                 ║"
        echo "╠════════════════════════════════════════╣"
        echo "║ Master Name: $INP_NAME"
        echo "║ Chat ID    : $INP_CHATID"
        echo "╠════════════════════════════════════════╣"
        echo "║ 🔑 API KEY (SAVE THIS!)               ║"
        echo "║                                        ║"
        echo "║ $API_KEY ║"
        echo "╚════════════════════════════════════════╝"
        echo ""
        echo "📝 Copy API key untuk install node!"
        echo ""
        
        # Send API key via Telegram
        curl -s -X POST "https://api.telegram.org/bot$INP_TOKEN/sendMessage" \
            -d chat_id="$INP_CHATID" \
            -d parse_mode="HTML" \
            --data-urlencode text="🔑 <b>Master Setup Complete</b>

<b>Server:</b> $INP_NAME
<b>API Key:</b> <code>$API_KEY</code>

Use this key when installing nodes." > /dev/null 2>&1
        
        echo "✉️  API key juga dikirim ke Telegram!"
        echo ""
        sleep 3
    else
        echo "Config missing. Cannot setup in background."
        exit 1
    fi
fi
source "$CONF_FILE"
MSG_ID_FILE="/root/.wibu_msg_id"

# 🛡️ BUKA FIREWALL PORT 5000 (Agar Node Bebas Mengirim Laporan)
iptables -I INPUT -p tcp --dport 5000 -j ACCEPT &> /dev/null
if command -v ufw &> /dev/null; then ufw allow 5000/tcp &> /dev/null; fi

# 3. SETUP API SERVER (PYTHON FLASK) - API Key Authentication
if ! command -v python3 &> /dev/null || ! command -v vnstat &> /dev/null; then
    if ! dpkg -l 2>/dev/null | grep -qE 'python3.*ii'; then
        apt update -y &> /dev/null
        apt install python3 python3-pip vnstat -y &> /dev/null
        pip3 install flask flask-limiter --quiet 2>/dev/null
    fi
fi

cat << 'EOF' > /root/api_server.py
from flask import Flask, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import re
import os
import tempfile
import time

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024  # 100KB max

limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["60 per minute"],
    storage_uri="memory://"
)

# Memory cache for node data (avoid disk I/O on reads)
node_cache = {}
CACHE_TTL = 55  # seconds

def get_api_key():
    """Read API key from master config"""
    try:
        with open("/root/.wibu_bot.conf", "r") as f:
            for line in f:
                if line.startswith("API_KEY"):
                    return line.split('"')[1]
    except:
        return None

@app.route('/api/report', methods=['POST'])
@limiter.limit("30 per minute")
def report():
    # Validate API key (replace IP whitelist)
    provided_key = request.headers.get('X-API-Key')
    expected_key = get_api_key()
    
    if not provided_key or provided_key != expected_key:
        return "Forbidden - Invalid API Key", 403
    
    vps_name = request.form.get('name', 'unknown')
    # Strict sanitization: alphanumeric, underscore, dash only
    vps_name = re.sub(r'[^a-zA-Z0-9_-]', '', vps_name)
    if not vps_name or len(vps_name) > 50:
        return "Invalid name", 400
    
    vps_data = request.form.get('data', '')
    if not vps_data or len(vps_data) > 90000:  # 90KB text limit
        return "Invalid data", 400
    
    # Update memory cache + disk
    node_cache[vps_name] = {'data': vps_data, 'time': time.time()}
    
    # Atomic write with temp file
    target_path = f"/root/node_{vps_name}.txt"
    try:
        with tempfile.NamedTemporaryFile(mode='w', dir='/root', delete=False) as tmp:
            tmp.write(vps_data)
            tmp_path = tmp.name
        os.rename(tmp_path, target_path)
        return "OK", 200
    except Exception as e:
        if 'tmp_path' in locals() and os.path.exists(tmp_path):
            os.unlink(tmp_path)
        return "Error", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
pkill -f api_server.py &> /dev/null

if ! pgrep -f "api_server.py" > /dev/null; then
    pkill -f api_server.py &> /dev/null
    nohup python3 /root/api_server.py > /dev/null 2>&1 &
fi

# 4. GATHER DATA VPS MASTER
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
if [ -z "$INTERFACE" ]; then
    INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]" {print $2;exit}' | xargs)
fi
if [ -z "$INTERFACE" ]; then
    INTERFACE="eth0"
fi

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || hostname -f)
IP_MASKED=$(echo "$IP_SEKARANG" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

# Cache geo data (IP doesn't change frequently)
GEO_CACHE="/root/.wibu_geo_cache"
if [ -f "$GEO_CACHE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$GEO_CACHE")))
    if [ $CACHE_AGE -lt 86400 ]; then
        CITY=$(cat "$GEO_CACHE")
    fi
fi

if [ -z "$CITY" ]; then
    GEO_DATA=$(curl -s --connect-timeout 5 --max-time 10 http://ip-api.com/json/$IP_SEKARANG)
    CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
    [ -z "$CITY" ] && CITY="Unknown"
    echo "$CITY" > "$GEO_CACHE"
fi

UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
UPTIME_FMT=$(printf "%02d Jam, %02d Menit" $(awk "BEGIN {print int($UPTIME_RAW/3600)}") $(awk "BEGIN {print int(($UPTIME_RAW%3600)/60)}"))

SPEED_TEST=$(vnstat -tr 1 -i $INTERFACE 2>/dev/null)
RX=$(echo "$SPEED_TEST" | grep "rx" | awk '{print $2}')
TX=$(echo "$SPEED_TEST" | grep "tx" | awk '{print $2}')
[ -z "$RX" ] && RX="N/A"
[ -z "$TX" ] && TX="N/A"

VNSTAT_DATA=$(vnstat -i $INTERFACE --oneline 2>/dev/null)
BW_TODAY=$(echo "$VNSTAT_DATA" | awk -F';' '{print $6}')
BW_MONTH=$(echo "$VNSTAT_DATA" | awk -F';' '{print $11}')
[ -z "$BW_TODAY" ] && BW_TODAY="N/A"
[ -z "$BW_MONTH" ] && BW_MONTH="N/A"

STATUS=$(pgrep -f "xray" > /dev/null && echo "🟢 <b>ACTIVE</b>" || echo "🔴 <b>CRITICAL</b>")

TEXT="🦊 <b>WIBU LIVE MONITOR</b> 🦊
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
    RESPONSE=$(curl -s --connect-timeout 10 --max-time 30 -X POST "https://api.telegram.org/bot$BOT_TOKEN/editMessageText" \
        -d chat_id="$CHAT_ID" \
        -d message_id="$MSG_ID" \
        --data-urlencode "text=$TEXT" \
        -d parse_mode="HTML")
    if echo "$RESPONSE" | grep -q -E '(message to edit not found|message_id.*not found)'; then
        rm -f "$MSG_ID_FILE"
    fi
else
    RESPONSE=$(curl -s --connect-timeout 10 --max-time 30 -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        --data-urlencode "text=$TEXT" \
        -d parse_mode="HTML")
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        MSG_ID=$(echo "$RESPONSE" | grep -o '"message_id":[0-9]*' | cut -d':' -f2)
        if [[ "$MSG_ID" =~ ^[0-9]+$ ]]; then
            echo "$MSG_ID" > "$MSG_ID_FILE"
        fi
    fi
fi

# 7. CRONJOB (with duplicate prevention)
SCRIPT_PATH=$(realpath "$0")
CRON_ENTRY="* * * * * $SCRIPT_PATH"
CRON_TEMP=$(mktemp)
crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" > "$CRON_TEMP"
echo "$CRON_ENTRY" >> "$CRON_TEMP"
crontab "$CRON_TEMP"
rm -f "$CRON_TEMP"
