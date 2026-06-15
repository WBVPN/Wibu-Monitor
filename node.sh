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

apt update -y &> /dev/null
apt install vnstat -y &> /dev/null

INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || hostname -f)
IP=$(curl -s ifconfig.me)
IP_MASKED=$(echo "$IP" | awk -F. '{print $1"."substr($2,1,2)"*.***.**"}')
DOMAIN_MASKED=$(echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}')

GEO_DATA=$(curl -s http://ip-api.com/json/$IP)
CITY=$(echo "$GEO_DATA" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
[ -z "$CITY" ] && CITY="Unknown"

UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
UPTIME_FMT=$(printf "%02d Jam, %02d Menit" $(awk "BEGIN {print int($UPTIME_RAW/3600)}") $(awk "BEGIN {print int(($UPTIME_RAW%3600)/60)}"))

SPEED_TEST=$(vnstat -tr 2 -i $INTERFACE 2>/dev/null)
RX=$(echo "$SPEED_TEST" | grep "rx" | awk '{print $2}')
TX=$(echo "$SPEED_TEST" | grep "tx" | awk '{print $2}')

BW_TODAY=$(vnstat -i $INTERFACE --oneline 2>/dev/null | awk -F';' '{print $6}')
BW_MONTH=$(vnstat -i $INTERFACE --oneline 2>/dev/null | awk -F';' '{print $11}')

STATUS=$(pgrep -x "xray" > /dev/null && echo "🟢 <b>ACTIVE</b>" || echo "🔴 <b>CRITICAL</b>")

DATA=" ┣ 🌐 <b>Domain :</b> <code>$DOMAIN_MASKED</code>
 ┣ 🔌 <b>IPv4   :</b> <code>$IP_MASKED</code>
 ┣ 🏙️ <b>Lokasi :</b> $CITY (Auto)
 ┣ ⏳ <b>Uptime :</b> $UPTIME_FMT
 ┣ 🚀 <b>Speed  :</b> <code>$RX ↓ / $TX ↑ Mbps</code>
 ┣ 📊 <b>Traffic :</b> Hari Ini: $BW_TODAY | Bulan: $BW_MONTH
 ┗ 🛡️ <b>Status :</b> $STATUS"

curl -s -X POST "http://$MASTER_IP:5000/api/report" -d "name=$VPS_NAME" -d "data=$DATA" > /dev/null

if ! crontab -l 2>/dev/null | grep -q "wibu_node.sh"; then
    (crontab -l 2>/dev/null; echo "* * * * * /root/wibu_node.sh $MASTER_IP \"$VPS_NAME\"") | crontab -
fi
