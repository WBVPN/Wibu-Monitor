#!/bin/bash

# ==========================================
# 🦊 WIBU MONITOR - UNINSTALL SCRIPT
# ==========================================

echo "╔════════════════════════════════════════╗"
echo "║   WIBU MONITOR - UNINSTALL             ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Select option:"
echo "1) Uninstall Master"
echo "2) Uninstall Node"
echo "3) Disable (pause) Master"
echo "4) Disable (pause) Node"
echo "5) Cancel"
echo ""
read -p "Choice [1-5]: " CHOICE

case $CHOICE in
    1)
        echo "⏳ Uninstalling Master..."
        pkill -f api_server.py
        pkill -f wibu_master.sh
        crontab -l 2>/dev/null | grep -v "wibu_master.sh" | crontab -
        
        echo ""
        read -p "Delete config & data? (y/n): " DEL_CONFIG
        if [ "$DEL_CONFIG" = "y" ]; then
            rm -f /root/.wibu_bot.conf /root/.wibu_msg_id /root/node_*.txt /root/.wibu_geo_cache
            rm -f /root/wibu_master.sh /root/api_server.py
            echo "✅ Master uninstalled completely"
        else
            rm -f /root/wibu_master.sh /root/api_server.py
            echo "✅ Master uninstalled (config preserved)"
            echo "📝 Config saved at: /root/.wibu_bot.conf"
        fi
        
        # Close firewall port
        iptables -D INPUT -p tcp --dport 5000 -j ACCEPT 2>/dev/null
        if command -v ufw &> /dev/null; then 
            ufw delete allow 5000/tcp 2>/dev/null
        fi
        ;;
    2)
        echo "⏳ Uninstalling Node..."
        pkill -f wibu_node.sh
        crontab -l 2>/dev/null | grep -v "wibu_node.sh" | crontab -
        rm -f /root/wibu_node.sh /root/.wibu_geo_cache_node /root/.wibu_node.conf
        echo "✅ Node uninstalled"
        ;;
    3)
        echo "⏸️  Pausing Master..."
        pkill -f api_server.py
        pkill -f wibu_master.sh
        crontab -l 2>/dev/null | grep -v "wibu_master.sh" | crontab -
        echo "✅ Master paused (config preserved)"
        echo "💡 Run ./wibu_master.sh to resume"
        ;;
    4)
        echo "⏸️  Pausing Node..."
        pkill -f wibu_node.sh
        crontab -l 2>/dev/null | grep -v "wibu_node.sh" | crontab -
        echo "✅ Node paused"
        echo "💡 Re-run installation command to resume"
        ;;
    5)
        echo "❌ Cancelled"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Done!"
