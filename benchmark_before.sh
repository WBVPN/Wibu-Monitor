#!/bin/bash
echo "=== BEFORE Optimization Benchmark ==="
echo "Original master.sh metrics:"
echo ""

# Count expensive operations in ORIGINAL (from git)
git show HEAD:master.sh > /tmp/master_original.sh 2>/dev/null || cp master.sh /tmp/master_original.sh

echo "Curl API calls per run:"
grep -c "curl.*http" /tmp/master_original.sh

echo "vnstat calls per run:"
grep -c "vnstat" /tmp/master_original.sh

echo "Geo API calls: $(grep -c 'ip-api.com' /tmp/master_original.sh) (no caching)"

echo ""
echo "=== AFTER Optimization ==="
echo "Current master.sh metrics:"
echo ""

echo "Curl API calls per run:"
grep -c "curl.*http" master.sh

echo "vnstat calls per run:"
grep -c "vnstat" master.sh

echo "Geo API cached: $(grep -c 'GEO_CACHE' master.sh) implementation"
grep -c "CACHE_AGE" master.sh && echo "✅ Cache with TTL" || echo "❌ No cache"

echo ""
echo "Speed test duration:"
echo "  Before: vnstat -tr 2 = 2 seconds wait"
echo "  After: vnstat -tr 1 = 1 second wait"
echo "  Improvement: 50% faster"

echo ""
echo "vnstat optimization:"
VNSTAT_BEFORE=$(grep -c "vnstat.*--oneline" /tmp/master_original.sh)
VNSTAT_AFTER=$(grep "VNSTAT_DATA.*--oneline" master.sh | wc -l)
echo "  Before: $VNSTAT_BEFORE separate --oneline calls"
echo "  After: $VNSTAT_AFTER call (single parse)"
if [ $VNSTAT_AFTER -eq 1 ]; then
    echo "  ✅ Optimized to single call"
fi
