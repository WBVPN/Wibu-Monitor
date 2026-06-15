#!/bin/bash

echo "🛑 Sedang melakukan uninstall Wibu Monitor..."

# 1. Hentikan proses
pkill -f api_server.py
pkill -f wibu_master.sh

# 2. Hapus Cronjob
crontab -l | grep -v "wibu_" | crontab -

# 3. Hapus file script & data
rm -f /root/wibu_master.sh
rm -f /root/wibu_node.sh
rm -f /root/api_server.py
rm -f /root/.wibu_bot.conf
rm -f /root/.wibu_msg_id
rm -f /root/node_*.txt

# 4. Tutup firewall (jika ada UFW)
if command -v ufw &> /dev/null; then
    ufw delete allow 5000/tcp &> /dev/null
fi

echo "✅ Wibu Monitor telah dihapus total."
