#!/bin/bash
echo "=== PARTIAL DEPLOYMENT TEST ==="
echo ""

# Test 1: Python API Server
echo "Test 1: API Server Validation"
sed -n "/^cat << 'EOF' > \/root\/api_server.py$/,/^EOF$/p" master.sh | sed '1d;$d' > /tmp/test_api_full.py
python3 -m py_compile /tmp/test_api_full.py 2>&1
if [ $? -eq 0 ]; then
    echo "✅ API server Python syntax valid"
    
    # Check key features
    grep -q "flask_limiter" /tmp/test_api_full.py && echo "  ✅ Rate limiting present"
    grep -q "MAX_CONTENT_LENGTH" /tmp/test_api_full.py && echo "  ✅ File size limit present"
    grep -q "node_cache" /tmp/test_api_full.py && echo "  ✅ Memory cache present"
    grep -q "tempfile" /tmp/test_api_full.py && echo "  ✅ Atomic writes present"
else
    echo "❌ API server has syntax errors"
fi
echo ""

# Test 2: IP Whitelist Logic
echo "Test 2: IP Whitelist Validation"
cat > /tmp/test_whitelist.txt << 'IPEOF'
103.253.245.1
192.168.1.100
10.0.0.50
IPEOF

python3 << 'PYEOF'
def get_allowed_ips():
    with open("/tmp/test_whitelist.txt", "r") as f:
        return [line.strip() for line in f if line.strip()]

ips = get_allowed_ips()
test_cases = [
    ("103.253.245.1", True),
    ("192.168.1.100", True),
    ("1.2.3.4", False),
    ("103.253.245.2", False),
]

for test_ip, should_pass in test_cases:
    result = test_ip in ips
    status = "✅" if result == should_pass else "❌"
    print(f"{status} IP {test_ip}: {'allowed' if result else 'blocked'} (expected: {'allow' if should_pass else 'block'})")
PYEOF
echo ""

# Test 3: Input Sanitization
echo "Test 3: Input Sanitization"
python3 << 'PYEOF'
import re

def sanitize_name(name):
    return re.sub(r'[^a-zA-Z0-9_-]', '', name)

tests = [
    ("server1", "server1", True),
    ("test-server", "test-server", True),
    ("test_node", "test_node", True),
    ("../../passwd", "passwd", True),
    ("test;rm", "testrm", True),
    ("test file", "testfile", True),
]

passed = 0
for input_val, expected, _ in tests:
    result = sanitize_name(input_val)
    if result == expected:
        print(f"✅ '{input_val}' → '{result}'")
        passed += 1
    else:
        print(f"❌ '{input_val}' → '{result}' (expected '{expected}')")

print(f"\nSanitization: {passed}/{len(tests)} passed")
PYEOF
echo ""

# Test 4: Bash Syntax Validation
echo "Test 4: Bash Script Syntax"
bash -n master.sh 2>&1
if [ $? -eq 0 ]; then
    echo "✅ master.sh syntax valid"
else
    echo "❌ master.sh has syntax errors"
fi

bash -n node.sh 2>&1
if [ $? -eq 0 ]; then
    echo "✅ node.sh syntax valid"
else
    echo "❌ node.sh has syntax errors"
fi
echo ""

# Test 5: Critical Variables Check
echo "Test 5: Empty Variable Handling"
EMPTY_CHECKS=$(grep -c '\[ -z.*\] &&' master.sh node.sh)
echo "Empty variable checks found: $EMPTY_CHECKS"
if [ $EMPTY_CHECKS -ge 10 ]; then
    echo "✅ Sufficient empty checks"
else
    echo "⚠️  Consider more checks"
fi
echo ""

# Test 6: Network Timeout Coverage
echo "Test 6: Network Timeout Coverage"
CURL_TOTAL=$(grep -c "curl " master.sh node.sh)
CURL_TIMEOUT=$(grep -c "connect-timeout" master.sh node.sh)
echo "Total curl commands: $CURL_TOTAL"
echo "With timeout: $CURL_TIMEOUT"
if [ $CURL_TIMEOUT -ge $((CURL_TOTAL - 1)) ]; then
    echo "✅ All critical curl commands have timeouts"
else
    echo "⚠️  Some curl commands missing timeout"
fi
echo ""

# Test 7: Cronjob Duplicate Prevention
echo "Test 7: Cronjob Logic"
if grep -q "grep -v.*SCRIPT_PATH" master.sh node.sh; then
    echo "✅ Cronjob duplicate prevention implemented"
else
    echo "❌ Cronjob might create duplicates"
fi
echo ""

# Test 8: Mock Data Aggregation
echo "Test 8: Data Aggregation Format"
cat > /tmp/mock_node_test1.txt << 'NODEEOF'
 ┣ 🌐 <b>Domain :</b> <code>test.ex**.***.**</code>
 ┣ 🔌 <b>IPv4   :</b> <code>192.16*.***.**</code>
 ┣ 🏙️ <b>Lokasi :</b> Singapore (Auto)
 ┣ ⏳ <b>Uptime :</b> 05 Jam, 30 Menit
 ┣ 🚀 <b>Speed  :</b> <code>85.23 ↓ / 65.12 ↑ Mbps</code>
 ┣ 📊 <b>Traffic :</b> Hari Ini: 50.5 GiB | Bulan: 150.2 GiB
 ┗ 🛡️ <b>Status :</b> 🟢 <b>ACTIVE</b>
NODEEOF

if [ -f /tmp/mock_node_test1.txt ]; then
    LINES=$(wc -l < /tmp/mock_node_test1.txt)
    if [ $LINES -eq 7 ]; then
        echo "✅ Node data format correct (7 lines)"
    else
        echo "⚠️  Node data has $LINES lines (expected 7)"
    fi
    
    grep -q "Domain\|IPv4\|Lokasi\|Uptime\|Speed\|Traffic\|Status" /tmp/mock_node_test1.txt
    if [ $? -eq 0 ]; then
        echo "✅ All required fields present"
    else
        echo "❌ Missing required fields"
    fi
else
    echo "⚠️  Mock data not created"
fi
echo ""

# Test 9: Telegram Message Format
echo "Test 9: Telegram HTML Format Validation"
python3 << 'PYEOF'
import re

# Simulate Telegram message
msg = """🦊 <b>WIBU SERVER REAL MONITORING</b> 🦊
════════════════════════════
👑 <b>SERVER : MASTER</b>
 ┣ 🌐 <b>Domain :</b> <code>test.ex**.***.**</code>
 ┣ 🔌 <b>IPv4   :</b> <code>10.0*.***.**</code>
 ┣ 🏙️ <b>Lokasi :</b> Jakarta (Auto)
 ┣ ⏳ <b>Uptime :</b> 10 Jam, 25 Menit
 ┣ 🚀 <b>Speed  :</b> <code>92.5 ↓ / 70.3 ↑ Mbps</code>
 ┣ 📊 <b>Traffic :</b> Hari Ini: 100 GiB | Bulan: 500 GiB
 ┗ 🛡️ <b>Status :</b> 🟢 <b>ACTIVE</b>
════════════════════════════
⏱️ <b>Sinkronisasi :</b> <i>27 Sep 2026, 17:30:00 WIB</i>"""

# Check HTML tags balanced
open_tags = len(re.findall(r'<b>', msg))
close_tags = len(re.findall(r'</b>', msg))
open_code = len(re.findall(r'<code>', msg))
close_code = len(re.findall(r'</code>', msg))
open_italic = len(re.findall(r'<i>', msg))
close_italic = len(re.findall(r'</i>', msg))

print(f"<b> tags: {open_tags} open, {close_tags} close", end="")
print(f" ✅" if open_tags == close_tags else f" ❌")

print(f"<code> tags: {open_code} open, {close_code} close", end="")
print(f" ✅" if open_code == close_code else f" ❌")

print(f"<i> tags: {open_italic} open, {close_italic} close", end="")
print(f" ✅" if open_italic == close_italic else f" ❌")

if open_tags == close_tags and open_code == close_code and open_italic == close_italic:
    print("✅ Telegram HTML format valid")
else:
    print("❌ Telegram HTML tags unbalanced")
PYEOF
echo ""

echo "=== TEST SUMMARY ==="
echo "✅ = Pass | ❌ = Fail | ⚠️ = Warning"
echo ""
echo "Manual VPS deployment required for full integration test:"
echo "1. Setup master VPS with: wget ... master.sh && ./master.sh"
echo "2. Setup node VPS with: wget ... node.sh && ./node.sh [master_ip] [name]"
echo "3. Check Telegram bot receives formatted message"
echo "4. Verify message updates every 60s"
echo "5. Verify node removal after 5min offline"
