<div align="center">

# 🦊 WIBU LIVE MONITOR

### *Real-Time Multi-Server Monitoring via Telegram Bot*

[![Version](https://img.shields.io/badge/version-3.0-blue.svg)](https://github.com/WBVPN/Wibu-Monitor)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-production-success.svg)](https://github.com/WBVPN/Wibu-Monitor)

**Monitor unlimited VPS servers with live metrics delivered straight to your Telegram**

[Features](#-features) •
[Quick Start](#-quick-start) •
[Installation](#-installation) •
[Demo](#-demo) •
[FAQ](#-faq)

</div>

---

## 🌟 Features

<table>
<tr>
<td width="50%">

### 🔐 **Zero Friction Setup**
- Auto-generated API keys
- No manual approval needed
- Self-service installation
- Support dynamic IP addresses

### ⚡ **Optimized Performance**
- 99.93% fewer API calls
- 40-50% faster execution
- Smart caching (24h geo data)
- Minimal bandwidth usage

</td>
<td width="50%">

### 📊 **Real-Time Metrics**
- Live speed monitoring
- Traffic statistics (daily/monthly)
- Server health status
- Auto geo-location detection

### 🛡️ **Production Ready**
- Rate limiting (30 req/min)
- Input sanitization
- Atomic file operations
- Network timeout protection

</td>
</tr>
</table>

---

## 📱 Demo

<div align="center">

### Live Monitoring Display

```
🦊 WIBU LIVE MONITOR 🦊
════════════════════════════
👑 SERVER : MASTER-ID
 ┣ 🌐 Domain : wibuvpn.priasa**.***.**
 ┣ 🔌 IPv4   : 103.25*.***.**
 ┣ 🏙️ Lokasi : Jakarta (Auto)
 ┣ ⏳ Uptime : 15 Jam, 42 Menit
 ┣ 🚀 Speed  : 95.23 ↓ / 78.45 ↑ Mbps
 ┣ 📊 Traffic : Hari Ini: 245.67 GiB | Bulan: 1.2 TiB
 ┗ 🛡️ Status : 🟢 ACTIVE

────────────────────────────
👑 SERVER : SG-NODE-1
 ┣ 🌐 Domain : sgnode.examp**.***.**
 ┣ 🔌 IPv4   : 192.16*.***.**
 ┣ 🏙️ Lokasi : Singapore (Auto)
 ┣ ⏳ Uptime : 08 Jam, 15 Menit
 ┣ 🚀 Speed  : 125.89 ↓ / 98.32 ↑ Mbps
 ┣ 📊 Traffic : Hari Ini: 156.34 GiB | Bulan: 892.5 GiB
 ┗ 🛡️ Status : 🟢 ACTIVE

════════════════════════════
⏱️ Sinkronisasi : 27 Sep 2026, 17:45:55 WIB
🌸 Data diperbarui otomatis setiap 60 detik.
```

</div>

---

## 🚀 Quick Start

### Prerequisites

- 🐧 Linux VPS (Ubuntu/Debian recommended)
- 🤖 Telegram Bot Token ([Get one from @BotFather](https://t.me/botfather))
- 💬 Telegram Chat ID ([Get from @userinfobot](https://t.me/userinfobot))

### Installation (2 Steps)

#### 1️⃣ Setup Master Server

```bash
wget -O /root/wibu_master.sh https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/main/master.sh
chmod +x /root/wibu_master.sh
./wibu_master.sh
```

**Output:**
```
╔════════════════════════════════════════╗
║ 🔑 API KEY (SAVE THIS!)               ║
║                                        ║
║ a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6    ║
╚════════════════════════════════════════╝
```

#### 2️⃣ Setup Node Servers

```bash
wget -O /root/wibu_node.sh https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/main/node.sh
chmod +x /root/wibu_node.sh
./wibu_node.sh [MASTER_IP] [NODE_NAME] [API_KEY]
```

**Example:**
```bash
./wibu_node.sh 103.253.245.1 SG-NODE-1 a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
```

<div align="center">

**🎉 Done! Check your Telegram bot for live monitoring!**

</div>

---

## 📖 Installation

<details>
<summary><b>Detailed Master Setup</b></summary>

### Master VPS (Control Center)

The master server aggregates data from all nodes and updates a single Telegram message.

**Step 1: Download script**
```bash
wget -O /root/wibu_master.sh https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/main/master.sh
chmod +x /root/wibu_master.sh
```

**Step 2: Run installation**
```bash
./wibu_master.sh
```

**Step 3: Enter configuration**
- Bot Token from [@BotFather](https://t.me/botfather)
- Chat ID from [@userinfobot](https://t.me/userinfobot)
- Master server name (e.g., "MASTER")

**Step 4: Save API Key**
- Displayed on screen after setup
- Sent to your Telegram
- Required for node installations

</details>

<details>
<summary><b>Detailed Node Setup</b></summary>

### Node VPS (Monitored Servers)

Each node sends metrics to the master server every 60 seconds.

**Step 1: Download script**
```bash
wget -O /root/wibu_node.sh https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/main/node.sh
chmod +x /root/wibu_node.sh
```

**Step 2: Install with parameters**
```bash
./wibu_node.sh [MASTER_IP] [NODE_NAME] [API_KEY]
```

**Parameters:**
- `MASTER_IP` - Master server IP address
- `NODE_NAME` - Unique name (e.g., SG-NODE-1, US-SERVER)
- `API_KEY` - Key from master setup (32 characters)

**Example:**
```bash
./wibu_node.sh 103.253.245.1 SG-NODE-1 a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
```

**Verification:**
```
⏳ Testing connection to master...
✅ API key valid! Installing...
✅ Node installed successfully!
📊 Monitoring active - check your Telegram bot.
```

</details>

---

## 🔧 Uninstallation

### Quick Uninstall

```bash
wget -O /tmp/uninstall.sh https://raw.githubusercontent.com/WBVPN/Wibu-Monitor/main/uninstall.sh
chmod +x /tmp/uninstall.sh
/tmp/uninstall.sh
```

### Manual Uninstall

<details>
<summary><b>Master Server</b></summary>

```bash
pkill -f api_server.py
pkill -f wibu_master.sh
crontab -l | grep -v "wibu_master.sh" | crontab -
rm -f /root/wibu_master.sh /root/api_server.py /root/.wibu_bot.conf
rm -f /root/.wibu_msg_id /root/node_*.txt /root/.wibu_geo_cache
```

</details>

<details>
<summary><b>Node Server</b></summary>

```bash
pkill -f wibu_node.sh
crontab -l | grep -v "wibu_node.sh" | crontab -
rm -f /root/wibu_node.sh /root/.wibu_geo_cache_node /root/.wibu_node.conf
```

</details>

---

## 📊 Monitored Metrics

| Metric | Description | Update Frequency |
|--------|-------------|------------------|
| 🚀 **Speed** | Real-time download/upload speed | Every 60 seconds |
| 📊 **Traffic** | Daily and monthly bandwidth usage | Accumulated |
| ⏳ **Uptime** | Server uptime in hours:minutes | Real-time |
| 🌐 **Domain** | Server domain (masked for privacy) | Static |
| 🔌 **IPv4** | Server IP address (masked) | Static |
| 🏙️ **Location** | Auto-detected city via geo-IP | Cached 24h |
| 🛡️ **Status** | Service health (Active/Critical) | Real-time |

---

## 💡 FAQ

<details>
<summary><b>How many nodes can I monitor?</b></summary>

Technically unlimited! However, we recommend:
- **Optimal:** Up to 100 nodes per master
- **Maximum tested:** 100+ nodes working smoothly

</details>

<details>
<summary><b>What's the bandwidth usage?</b></summary>

**Per Node:**
- Download: ~0.7 KB/day (negligible)
- Upload: ~1.5 MB/day
- **Total:** ~45 MB/month (0.0045% of 1TB quota)

**Impact:** Practically zero! Won't affect VPN users.

</details>

<details>
<summary><b>What happens if a node goes offline?</b></summary>

- Node stops reporting to master
- After 5 minutes offline: automatically removed from display
- When back online: automatically re-appears

</details>

<details>
<summary><b>Can I change the API key?</b></summary>

Yes! Edit `/root/.wibu_bot.conf` on master and regenerate:
```bash
openssl rand -hex 16
```
Then update all nodes with the new key.

</details>

<details>
<summary><b>Does it support IPv6?</b></summary>

Currently IPv4 only. IPv6 support planned for future release.

</details>

<details>
<summary><b>Can I customize the update interval?</b></summary>

Yes! Default is 60 seconds. Edit crontab:
```bash
crontab -e
# Change: * * * * * (every minute)
# To: */2 * * * * (every 2 minutes)
```

</details>

<details>
<summary><b>What if I lose my API key?</b></summary>

Check master config:
```bash
grep API_KEY /root/.wibu_bot.conf
```
Or check Telegram message history (key was sent during setup).

</details>

---

## 🔒 Security Features

- ✅ **API Key Authentication** - Unique 32-char cryptographic keys
- ✅ **Rate Limiting** - 30 requests/min per IP
- ✅ **Input Sanitization** - Blocks injection attacks
- ✅ **File Size Limits** - 100KB max request size
- ✅ **Network Timeouts** - Prevents hanging connections
- ✅ **Atomic Operations** - No data corruption

---

## 📈 Performance

### Optimizations Applied

| Feature | Before | After | Improvement |
|---------|--------|-------|-------------|
| Geo API calls | 1,440/day | 1/day | **99.93%** ↓ |
| Speed test | 2 seconds | 1 second | **50%** ↓ |
| vnstat calls | 5/run | 3/run | **40%** ↓ |
| API disk I/O | Every request | Cached 55s | **~90%** ↓ |
| Execution time | 4-5s | 2-3s | **40-50%** ↓ |

### Resource Usage (Per Server)

| Resource | Usage | Impact |
|----------|-------|--------|
| CPU | < 1% | Negligible |
| RAM | ~20 MB (Master) / ~3 MB (Node) | Minimal |
| Disk | ~100 KB | Extremely low |
| Bandwidth | ~1.5 MB/day | Practically zero |

---

## 🛠️ Troubleshooting

### Node not appearing in Telegram

**Check API key:**
```bash
# Master
grep API_KEY /root/.wibu_bot.conf

# Node
grep API_KEY /root/.wibu_node.conf
```
Keys must match exactly!

**Check master running:**
```bash
pgrep -f api_server.py  # Should return a process ID
```

**Test connection:**
```bash
curl -H "X-API-Key: YOUR_KEY" -X POST http://MASTER_IP:5000/api/report -d "name=test" -d "data=test"
# Should return: OK
```

### Master not updating

**Check cron:**
```bash
crontab -l | grep wibu
# Should show: * * * * * /root/wibu_master.sh
```

**Check logs:**
```bash
tail -f /var/log/syslog | grep wibu
```

**Test manually:**
```bash
/root/wibu_master.sh
```

---

## 📋 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

**Latest: v3.0** (2026-09-27)
- ✨ API Key authentication (no more IP whitelist)
- 🎨 Rebranded to WIBU LIVE MONITOR
- ⚡ Performance optimizations (40-50% faster)
- 🔒 Security hardening (13 fixes)
- 🐛 Bug fixes (17 issues resolved)

---

## 🤝 Support

- 📧 **Issues:** [GitHub Issues](https://github.com/WBVPN/Wibu-Monitor/issues)
- 💬 **Telegram:** [@wibuvpn](https://t.me/wibuvpn)
- 📱 **WhatsApp:** [087757315408](https://wa.me/6287757315408)

---

## 📄 License

MIT License - feel free to use and modify!

---

<div align="center">

**Made with 🦊 by WBVPN Team**

⭐ Star this repo if you find it useful!

[⬆ Back to Top](#-wibu-live-monitor)

</div>
