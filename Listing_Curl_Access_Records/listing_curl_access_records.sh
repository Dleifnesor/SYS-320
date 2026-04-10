#!/usr/bin/env bash
# listing_curl_access_records.sh
# SYS-320-01 | Listing Curl Access Records
# Adds countingCurlAccess function to an Apache log analysis script.
# Can also be sourced as a standalone function library.

set -euo pipefail

LOG="${1:-/var/log/apache2/access.log}"

usage() {
    echo "Usage: $0 [log_file]"
    echo "  log_file  - Path to Apache access log (default: /var/log/apache2/access.log)"
    exit 1
}

# Counts curl accesses per unique IP.
# curl requests are identified by the presence of "curl" in the User-Agent field ($12).
# In Combined Log Format, field order is:
#   $1=IP $4=date $5=time $6=method+path $9=status $10=bytes $11=referer $12=user-agent
# The user-agent spans multiple fields when it contains spaces, so grep is more reliable.
countingCurlAccess() {
    local log_file="${1:-$LOG}"

    if [[ ! -f "$log_file" ]]; then
        echo "[!] Log file not found: $log_file"
        return 1
    fi

    echo "=== curl Access Count by IP ==="
    echo ""

    # grep for lines where user-agent contains 'curl', then count per IP ($1)
    grep -i 'curl' "$log_file" \
        | awk '{print $1}' \
        | sort \
        | uniq -c \
        | sort -rn \
        | awk '{printf "  %-6s requests from %s\n", $1, $2}'

    echo ""
    echo "Total curl requests: $(grep -ci 'curl' "$log_file" || echo 0)"
}

# Also show the raw curl lines for verification
showCurlLines() {
    local log_file="${1:-$LOG}"
    echo ""
    echo "=== Raw curl log entries ==="
    grep -i 'curl' "$log_file" | head -20
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && usage

echo "[*] Analyzing: $LOG"
echo ""
countingCurlAccess "$LOG"
showCurlLines "$LOG"
