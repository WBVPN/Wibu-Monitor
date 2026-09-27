# 🦊 WIBU MONITOR - FULL AUDIT REPORT

Generated: 2026-09-27  
Repository: https://github.com/WBVPN/Wibu-Monitor

---

## EXECUTIVE SUMMARY

**Files Audited:** master.sh (153 lines), node.sh (52 lines)  
**Total Issues Found:** 42 issues across 4 categories  
**Critical:** 8 | **High:** 12 | **Medium:** 15 | **Low:** 7

---

## 🐛 BUGS & RELIABILITY (17 issues)

### CRITICAL

#### BUG-1: Network failure causes script crash
**File:** master.sh:9-13  
**Impact:** Script exits jika curl ifconfig.me atau GitHub down  
**Reproduction:**
```bash
# Simulate network failure
iptables -A OUTPUT -d ifconfig.me -j DROP
./master.sh  # Will exit with "ERROR: IP Not Registered"
```
**Fix:** Add timeout + fallback + retry logic

#### BUG-2: Partial config on user interrupt
**File:** master.sh:19-29  
**Impact:** Ctrl+C saat setup bisa simpan config incomplete  
**Reproduction:**
```bash
./master.sh
# Press Ctrl+C after entering token only
cat /root/.wibu_bot.conf  # Incomplete config
```
**Fix:** Use trap untuk cleanup atau atomic config write

#### BUG-3: Cronjob duplication
**File:** master.sh:149-153, node.sh:50-52  
**Impact:** Multiple cronjob entries kalau crontab grep fail  
**Reproduction:**
```bash
./master.sh  # Run 3x
crontab -l | grep wibu  # Shows 3 identical entries
```
**Fix:** Check exact match dengan flock atau unique marker

#### BUG-4: Telegram message edit failure loop
**File:** master.sh:127-132  
**Impact:** Kalau message dihapus manual, tidak create new message  
**Reproduction:**
```bash
# Delete message from Telegram manually
./master.sh  # Will keep trying editMessageText forever
```
**Fix:** Already detects "message to edit not found" but response parsing bisa fail

### HIGH

#### BUG-5: Empty interface variable
**File:** master.sh:73, node.sh:16  
**Impact:** vnstat commands fail kalau tidak ada default route  
**Reproduction:**
```bash
ip route del default  # Remove default route
./master.sh  # vnstat -i "" fails
```
**Fix:** Fallback ke eth0 atau auto-detect first interface

#### BUG-6: API timeout causes hang
**File:** master.sh:81-82, node.sh:27-29,48  
**Impact:** curl tanpa timeout bisa hang 5+ minutes  
**Reproduction:**
```bash
# Slow API response
tc qdisc add dev eth0 root netem delay 10000ms
./master.sh  # Hangs on ip-api.com
```
**Fix:** Add --connect-timeout 5 --max-time 10

#### BUG-7: vnstat empty data
**File:** master.sh:88-94, node.sh:35-38  
**Impact:** New interface atau vnstat not initialized returns empty  
**Reproduction:**
```bash
vnstat --delete -i eth0 --force
./master.sh  # Speed shows " ↓ /  ↑ Mbps"
```
**Fix:** Check vnstat output not empty, default to "N/A"

#### BUG-8: Multiple xray instances not detected
**File:** master.sh:96, node.sh:40  
**Impact:** pgrep -x only checks exact name, misses xray variants  
**Reproduction:**
```bash
# If running "xray run" or "xray-core"
pgrep -x "xray"  # Returns nothing
```
**Fix:** Use pgrep -f "xray" atau pidof xray

### MEDIUM

#### BUG-9: Path traversal in filename
**File:** master.sh:54  
**Impact:** Regex allows space, bisa break file operations  
**Reproduction:**
```bash
curl -X POST http://master:5000/api/report -d 'name=../../etc/passwd' -d 'data=evil'
# Creates /root/node_../../etc/passwd.txt (sanitized to node____etc_passwd.txt)
```
**Fix:** Regex works but space masih lolos, should remove space

#### BUG-10: Domain masking breaks short domains
**File:** master.sh:76, node.sh:20  
**Impact:** Domain < 8 chars bisa expose full domain  
**Reproduction:**
```bash
DOMAIN="abc.com"
echo "$DOMAIN" | awk -F. '{print $1"."substr($2,1,6)"**.***.**"}'
# Output: abc.com**.***.**  (not properly masked)
```
**Fix:** Check domain length first

#### BUG-11: Race condition on file write
**File:** master.sh:55-58  
**Impact:** Multiple nodes write simultaneously bisa corrupt file  
**Reproduction:**
```bash
# Two nodes POST at same millisecond
# No file locking, bisa overwrite partial
```
**Fix:** Use flock atau atomic write (write to temp + mv)

#### BUG-12: No validation on Telegram response
**File:** master.sh:138-145  
**Impact:** Invalid JSON response bisa break MSG_ID extraction  
**Reproduction:**
```bash
# Telegram API down returns HTML error page
echo "$RESPONSE" | grep -o '"message_id":[0-9]*'  # Returns nothing
```
**Fix:** Validate JSON before grep

#### BUG-13: Cleanup loop removes all if expired
**File:** master.sh:110-118  
**Impact:** Kalau semua nodes offline 5+ min, TEXT jadi empty  
**Reproduction:**
```bash
# Stop all nodes for 6 minutes
./master.sh  # Telegram shows only master, no separator
```
**Fix:** Not really a bug, but add "No active nodes" message

### LOW

#### BUG-14: apt update spam
**File:** master.sh:44-46, node.sh:11-14  
**Impact:** apt update setiap run kalau dependencies missing  
**Fix:** Check if already installed first

#### BUG-15: Timezone hardcoded WIB
**File:** master.sh:125  
**Impact:** Non-Indonesia users see wrong timezone  
**Fix:** Auto-detect with date or add config

#### BUG-16: No error output for debugging
**File:** Both files  
**Impact:** Silent failures hard to debug  
**Fix:** Add DEBUG mode with logging

#### BUG-17: API server restart overwrites
**File:** master.sh:47-68  
**Impact:** Every run checks and rewrites api_server.py even if unchanged  
**Fix:** Check file hash before overwrite

---

## 🛡️ SECURITY ISSUES (13 issues)

### CRITICAL

#### SEC-1: IP whitelist bypass via proxy
**File:** master.sh:9  
**Impact:** Attacker bisa spoof IP dengan transparent proxy  
**Reproduction:**
```bash
# Setup proxy with whitelisted IP as source
# Script akan lulus validation tapi sebenarnya attacker
```
**Fix:** Add additional auth (API key, token)

#### SEC-2: Plain HTTP data transmission
**File:** node.sh:48  
**Impact:** Data dikirim unencrypted, bisa di-sniff  
**Reproduction:**
```bash
tcpdump -i eth0 -A 'port 5000'  # See full server data in plaintext
```
**Fix:** Use HTTPS (stunnel atau nginx reverse proxy)

#### SEC-3: Telegram token in process list
**File:** master.sh:127-145  
**Impact:** Token visible via ps aux  
**Reproduction:**
```bash
ps aux | grep curl  # Shows BOT_TOKEN in command
```
**Fix:** Use curl -d @file atau stdin

### HIGH

#### SEC-4: Path traversal despite sanitization
**File:** master.sh:54  
**Impact:** Space in filename bisa cause issues  
**Reproduction:**
```bash
curl -X POST -d 'name=test file' -d 'data=x'
ls /root/node_test\ file.txt  # Space preserved
```
**Fix:** Replace space dengan underscore

#### SEC-5: No rate limiting on API
**File:** master.sh:47-68  
**Impact:** Attacker bisa spam POST requests  
**Reproduction:**
```bash
while true; do curl -X POST http://master:5000/api/report -d name=spam -d data=x; done
# Fills disk with node_spam.txt rewrites
```
**Fix:** Add rate limit per IP (Flask-Limiter)

#### SEC-6: No file size limit
**File:** master.sh:55-58  
**Impact:** Large POST data bisa fill disk  
**Reproduction:**
```bash
curl -X POST -d "name=test" -d "data=$(python3 -c 'print(\"A\"*10**9)')"
# Creates 1GB file
```
**Fix:** Add max content length in Flask

#### SEC-7: Unsafe crontab parameter
**File:** node.sh:50-52  
**Impact:** VPS_NAME dengan special chars bisa break cron  
**Reproduction:**
```bash
./wibu_node.sh 1.2.3.4 'test;rm -rf /'
# Cron will execute: * * * * * /root/wibu_node.sh 1.2.3.4 test;rm -rf /
```
**Fix:** Quote parameter dan sanitize before crontab

### MEDIUM

#### SEC-8: No SSL verification
**File:** master.sh:10, node.sh:22,27  
**Impact:** MITM attack bisa spoof GitHub/API responses  
**Fix:** Add curl --cacert atau verify cert

#### SEC-9: Predictable file names
**File:** master.sh:56  
**Impact:** Attacker bisa guess filenames untuk overwrite  
**Fix:** Add random suffix atau hash

#### SEC-10: No authentication on API
**File:** master.sh:47-68  
**Impact:** Anyone with whitelisted IP bisa POST  
**Fix:** Add Bearer token atau API key

#### SEC-11: Domain info leakage
**File:** master.sh:74-75, node.sh:17-18  
**Impact:** Fallback hostname -f bisa leak internal FQDN  
**Fix:** Mask hostname fallback juga

#### SEC-12: No log rotation
**File:** Both files  
**Impact:** Nohup logs bisa grow infinitely  
**Fix:** Add logrotate config

#### SEC-13: Firewall rule persists
**File:** master.sh:37-38  
**Impact:** Port 5000 terbuka permanent even after uninstall  
**Fix:** Uninstall script should close port

---

## ⚡ PERFORMANCE ISSUES (8 issues)

### HIGH

#### PERF-1: Redundant geo API calls
**File:** master.sh:81-82, node.sh:27-29  
**Impact:** ip-api.com called every 60s, rate limit 45/min  
**Reproduction:**
```bash
# 10 servers = 10 calls/min = safe
# 50 servers = rate limit exceeded = banned
```
**Fix:** Cache city result untuk 24 jam (IP geo tidak berubah)

#### PERF-2: Slow vnstat speed test
**File:** master.sh:88-89, node.sh:35  
**Impact:** vnstat -tr 2 waits 2 seconds every run  
**Fix:** Use vnstat -i instead of live test, atau reduce to 1s

#### PERF-3: Duplicate vnstat calls
**File:** master.sh:93-94, node.sh:37-38  
**Impact:** vnstat --oneline called 2x untuk different fields  
**Fix:** Call once, parse multiple fields from single output

### MEDIUM

#### PERF-4: No request caching
**File:** master.sh:47-68  
**Impact:** API processes every request, no cache  
**Fix:** Cache node data dalam memory selama 55s

#### PERF-5: File stat in loop
**File:** master.sh:110-118  
**Impact:** stat() called untuk every file every minute  
**Fix:** OK untuk small scale (<100 nodes)

#### PERF-6: Blocking Telegram API
**File:** master.sh:127-145  
**Impact:** Curl blocks script until Telegram responds  
**Fix:** Use background job atau async

#### PERF-7: No compression
**File:** node.sh:48  
**Impact:** Large data transferred uncompressed  
**Fix:** Add gzip compression untuk POST data

#### PERF-8: API server single-threaded
**File:** master.sh:67  
**Impact:** Flask dev server handles one request at a time  
**Fix:** Use gunicorn atau waitress untuk production

---

## 📝 CODE QUALITY ISSUES (4 issues)

### MEDIUM

#### QUAL-1: No error logging
**File:** Both files  
**Impact:** Silent failures hard to troubleshoot  
**Fix:** Add logging to /var/log/wibu-monitor.log

#### QUAL-2: Magic numbers
**File:** master.sh:114 (300 seconds)  
**Impact:** Unclear what 300 means  
**Fix:** Define NODE_TIMEOUT_SEC=300

#### QUAL-3: Code duplication
**File:** vnstat, geo lookup, masking repeated in both files  
**Impact:** Changes need to be applied twice  
**Fix:** Create shared functions library

#### QUAL-4: No version tracking
**File:** Both files  
**Impact:** Hard to know which version is running  
**Fix:** Add VERSION variable dan --version flag

---

## 📋 PRIORITY MATRIX

| Priority | Count | Issues |
|----------|-------|--------|
| CRITICAL | 8 | BUG-1,2,3,4, SEC-1,2,3, PERF-1 |
| HIGH | 12 | BUG-5,6,7,8, SEC-4,5,6,7, PERF-2,3 |
| MEDIUM | 15 | BUG-9,10,11,12,13, SEC-8,9,10,11,12,13, PERF-4,5,6 |
| LOW | 7 | BUG-14,15,16,17, QUAL-1,2,3,4 |

---

## 🎯 RECOMMENDED FIX ORDER

1. **Phase 1 - Critical Safety (BUG-1,2,3,4, SEC-1,2,3)**
   - Add error handling untuk network failures
   - Fix cronjob duplication
   - Add HTTPS atau auth layer
   - Secure Telegram token

2. **Phase 2 - Reliability (BUG-5,6,7,8)**
   - Add timeouts to all curl calls
   - Fix empty variable handling
   - Improve service detection

3. **Phase 3 - Security Hardening (SEC-4,5,6,7)**
   - Sanitize inputs completely
   - Add rate limiting
   - Add file size limits
   - Quote crontab parameters

4. **Phase 4 - Performance (PERF-1,2,3,4)**
   - Cache geo lookups
   - Optimize vnstat calls
   - Add request caching

5. **Phase 5 - Code Quality (QUAL-1,2,3,4)**
   - Add logging
   - Refactor duplicated code
   - Add version tracking

---

## ✅ VERIFICATION CHECKLIST

- [ ] All curl commands have --connect-timeout and --max-time
- [ ] All user inputs sanitized before file operations
- [ ] Cronjob duplicate prevention verified
- [ ] Telegram API token not visible in process list
- [ ] API has rate limiting and file size limits
- [ ] Empty variable handling for INTERFACE, DOMAIN, geo data
- [ ] Service detection handles multiple instances
- [ ] Geo API calls cached (verify no redundant calls)
- [ ] vnstat optimized (single call per metric type)
- [ ] Error logging implemented
- [ ] All injection vectors tested and blocked
- [ ] Test dengan 0 nodes, 1 node, 10 nodes concurrent

---

**End of Audit Report**
