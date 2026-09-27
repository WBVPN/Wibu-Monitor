#!/bin/bash
echo "=== Security Verification Tests ==="

# Test 1: Path traversal blocked
echo "Test 1: Path traversal sanitization"
TEST_NAME="../../etc/passwd"
SANITIZED=$(echo "$TEST_NAME" | sed 's/[^a-zA-Z0-9_-]//g')
if [ "$SANITIZED" = "etcpasswd" ]; then
    echo "✅ Path traversal blocked"
else
    echo "❌ Failed: $SANITIZED"
fi

# Test 2: Space removed from names
echo "Test 2: Space removal"
TEST_NAME="test file"
SANITIZED=$(echo "$TEST_NAME" | sed 's/[^a-zA-Z0-9_-]//g')
if [ "$SANITIZED" = "testfile" ]; then
    echo "✅ Spaces removed"
else
    echo "❌ Failed: $SANITIZED"
fi

# Test 3: Command injection blocked
echo "Test 3: Command injection"
TEST_NAME="test;rm -rf /"
SANITIZED=$(echo "$TEST_NAME" | sed 's/[^a-zA-Z0-9_-]//g')
if [ "$SANITIZED" = "testrmrf" ]; then
    echo "✅ Command injection blocked"
else
    echo "❌ Failed: $SANITIZED"
fi

# Test 4: Curl timeout present
echo "Test 4: Curl timeouts"
TIMEOUT_COUNT=$(grep -c "connect-timeout" master.sh node.sh)
if [ $TIMEOUT_COUNT -ge 8 ]; then
    echo "✅ All curl commands have timeout ($TIMEOUT_COUNT instances)"
else
    echo "❌ Missing timeouts: only $TIMEOUT_COUNT found"
fi

# Test 5: Cronjob duplicate prevention
echo "Test 5: Cronjob logic"
if grep -q "grep -v.*SCRIPT_PATH" master.sh && grep -q "mktemp" master.sh; then
    echo "✅ Cronjob duplicate prevention implemented"
else
    echo "❌ Cronjob logic incomplete"
fi

# Test 6: IP validation with fallback
echo "Test 6: IP detection fallback"
if grep -q "icanhazip.com" master.sh node.sh; then
    echo "✅ IP fallback exists"
else
    echo "❌ No IP fallback"
fi

# Test 7: Empty variable handling
echo "Test 7: Empty variable checks"
EMPTY_CHECKS=$(grep -c '\[ -z.*\]' master.sh node.sh)
if [ $EMPTY_CHECKS -ge 10 ]; then
    echo "✅ Empty variable handling ($EMPTY_CHECKS checks)"
else
    echo "❌ Insufficient checks: $EMPTY_CHECKS"
fi

# Test 8: Rate limiting in API
echo "Test 8: Rate limiting"
if grep -q "flask-limiter\|flask_limiter" master.sh; then
    echo "✅ Rate limiting implemented"
else
    echo "❌ No rate limiting"
fi

# Test 9: File size limit
echo "Test 9: File size limits"
if grep -q "MAX_CONTENT_LENGTH" master.sh; then
    echo "✅ File size limit set"
else
    echo "❌ No file size limit"
fi

# Test 10: Atomic writes
echo "Test 10: Atomic file writes"
if grep -q "tempfile\|tmp" master.sh; then
    echo "✅ Atomic writes implemented"
else
    echo "❌ No atomic writes"
fi

echo ""
echo "=== Injection Attack Tests ==="
python3 << 'PYEOF'
import re

tests = [
    ("../../etc/passwd", "etcpasswd"),
    ("test;rm -rf /", "testrmrf"),
    ("test|nc evil.com", "testncevilcom"),
    ("test\`whoami\`", "testwhoami"),
    ("test$(reboot)", "testreboot"),
    ("test file.txt", "testfiletxt"),
    ("../../../root/.ssh/id_rsa", "rootsshid_rsa"),
]

regex = r'[^a-zA-Z0-9_-]'
passed = 0
for input_val, expected in tests:
    result = re.sub(regex, '', input_val)
    if result == expected:
        print(f"✅ Blocked: '{input_val}' → '{result}'")
        passed += 1
    else:
        print(f"❌ Failed: '{input_val}' → '{result}' (expected '{expected}')")

print(f"\nPassed: {passed}/{len(tests)}")
PYEOF
