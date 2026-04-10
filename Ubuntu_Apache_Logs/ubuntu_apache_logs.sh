#!/usr/bin/env bash
# ubuntu_apache_logs.sh
# SYS-320-01 | Ubuntu Apache Logs
# Installs Apache2, generates sample log traffic, and reports on log location/format.
# Run on Ubuntu VM with sudo access.

set -euo pipefail

MODE="${1:---setup}"

usage() {
    echo "Usage: $0 [--setup | --generate | --analyze]"
    echo "  --setup     Install and start Apache2, display IP"
    echo "  --generate  Send curl requests to populate access.log"
    echo "  --analyze   Show log file locations and sample entries"
    exit 1
}

setup_apache() {
    echo "[*] Updating package lists"
    sudo apt-get update -qq

    echo "[*] Installing Apache2"
    sudo apt-get install -y apache2

    echo "[*] Starting Apache2"
    sudo service apache2 start
    sudo service apache2 status | head -10

    echo ""
    echo "[*] Your IP address:"
    ip addr | awk '/inet / && !/127.0.0.1/ {split($2, a, "/"); print a[1]; exit}'

    echo ""
    echo "[*] Default page available at:"
    IP=$(ip addr | awk '/inet / && !/127.0.0.1/ {split($2, a, "/"); print a[1]; exit}')
    echo "    http://${IP}/"
    echo ""
    echo "[*] Log files:"
    echo "    /var/log/apache2/access.log"
    echo "    /var/log/apache2/error.log"
}

generate_traffic() {
    IP=$(ip addr | awk '/inet / && !/127.0.0.1/ {split($2, a, "/"); print a[1]; exit}')
    BASE="http://${IP}"
    echo "[*] Generating varied log traffic against $BASE"

    # Normal browser-like requests
    curl -s -A "Mozilla/5.0 (X11; Linux x86_64)" "$BASE/" -o /dev/null
    curl -s -A "Mozilla/5.0 (Windows NT 10.0)" "$BASE/index.html" -o /dev/null

    # curl user-agent requests (for countingCurlAccess activity)
    curl -s "$BASE/" -o /dev/null
    curl -s "$BASE/about.html" -o /dev/null
    curl -s "$BASE/contact.html" -o /dev/null

    # 404 errors
    curl -s "$BASE/notfound.html" -o /dev/null
    curl -s "$BASE/admin/" -o /dev/null

    # Additional curl hits from "different" perspective
    for i in 1 2 3; do
        curl -s "$BASE/page${i}.php" -o /dev/null
    done

    echo "[*] Traffic generated. Check log:"
    echo "    sudo tail -20 /var/log/apache2/access.log"
}

analyze_logs() {
    LOG="/var/log/apache2/access.log"
    echo "[*] Log file: $LOG"
    echo "[*] Size: $(wc -l < "$LOG") lines"
    echo ""
    echo "[*] Last 15 entries:"
    sudo tail -15 "$LOG"
    echo ""
    echo "[*] Log format breakdown (Common Log Format):"
    cat <<'EOF'
  Field 1: Client IP
  Field 2: Ident (usually -)
  Field 3: Auth user (usually -)
  Field 4: [Timestamp]
  Field 5: "METHOD /path HTTP/version"
  Field 6: Status code
  Field 7: Response size in bytes
  Field 8: (Combined format) "Referer"
  Field 9: (Combined format) "User-Agent"

Example:
  10.0.17.5 - - [01/Apr/2026:10:23:45 +0000] "GET / HTTP/1.1" 200 11173 "-" "curl/7.88.1"
EOF
    echo ""
    echo "[*] Top requesting IPs:"
    sudo awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -10
    echo ""
    echo "[*] curl access count:"
    sudo grep -c 'curl' "$LOG" || echo "0"
    echo ""
    echo "[*] HTTP status code breakdown:"
    sudo awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn
}

case "$MODE" in
    --setup)    setup_apache ;;
    --generate) generate_traffic ;;
    --analyze)  analyze_logs ;;
    *)          usage ;;
esac
