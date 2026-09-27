#!/bin/bash

# ==========================================
# 🦊 WIBU MONITOR - NODE SCRIPT (PREMIUM LAYOUT)
# ==========================================

MASTER_IP=$1
VPS_NAME=$2

if [ -z "$MASTER_IP" ] || [ -z "$VPS_NAME" ]; then
    echo "❌ Cara pakai: ./wibu_node.sh [IP_MASTER] [NAMA_VPS]"
    exit 1
fi

if ! command -v vnstat &> /dev/null; then
    if ! dpkg -l | grep -q vnstat; then
        apt update -y &> /dev/null
        apt install vnstat -y &> /dev/null
    fi
fi

INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
if [ -z "$INTERFACE" ]; then
    INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]" {print $2;exit}' | xargs)
fi
[ -z "$INTERFACE" ] && INTERFACE="eth0"

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || hostname -f)
IP=$(curl -s --connect-timeout 5 --max-time 10 ifconfig.me)
[ -z "$IP" ] && IP=$(curl -s --connect-timeout 5 --max-time 10 icanhazip.com)
if [ -z "$IP" ]; then
    echo "❌ Cannot detect IP"
    exit 1
fi
IP_MASKED=$(echo "$IP" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

GEO_CACHE="/root/.wibu_geo_cache_node"
if [ -f "$GEO_CACHE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$GEO_CACHE")))
    if [ $CACHE_AGE -lt 86400 ]; then
        CITY=$(cat "$GEO_CACHE")
    fi
fi

if [ -z "$CITY" ]; then
    GEO_DATA=$(curl -s --connect-timeout 5 --max-time 10 http://ip-api.com/json/$IP)
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

DATA=" ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> $CITY (Auto)
 ┣ ⏳ <b>Uptime :</b> $UPTIME_FMT
 ┣ 🚀 <b>Speed  :</b> <code>$RX ↓ / $TX ↑ Mbps</code>
 ┣ 📊 <b>Traffic :</b> Hari Ini: $BW_TODAY | Bulan: $BW_MONTH
 ┗ 🛡️ <b>Status :</b> $STATUS"

curl -s --connect-timeout 5 --max-time 10 -X POST "http://$MASTER_IP:5000/api/report" -d "name=$VPS_NAME" -d "data=$DATA" > /dev/null 2>&1

CRON_ENTRY="* * * * * /root/wibu_node.sh $MASTER_IP '$VPS_NAME'"
CRON_TEMP=$(mktemp)
crontab -l 2>/dev/null | grep -v "wibu_node.sh" > "$CRON_TEMP"
echo "$CRON_ENTRY" >> "$CRON_TEMP"
crontab "$CRON_TEMP"
rm -f "$CRON_TEMP"
