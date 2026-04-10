#!/usr/bin/env bash
# apacheLogMenu.bash
# SYS-320-01 | Linux Bash Apache Log Menu
# Menu-driven Apache log analysis tool.
# Functions: displayOnlyPages, frequentVisitors, suspiciousVisitors, countingCurlAccess

set -euo pipefail

LOG="${APACHE_LOG:-/var/log/apache2/access.log}"
IOC_FILE="${IOC_FILE:-./ioc.txt}"

##############################################################################
# displayOnlyPages
# Lists all unique page paths requested (GET requests), sorted by frequency.
##############################################################################
displayOnlyPages() {
    echo ""
    echo "=== Pages Requested ==="
    if [[ ! -f "$LOG" ]]; then
        echo "[!] Log not found: $LOG"
        return 1
    fi

    awk '$6 == "\"GET"' "$LOG" \
        | awk '{print $7}' \
        | sort \
        | uniq -c \
        | sort -rn \
        | awk '{printf "  %-6s %s\n", $1, $2}'
    echo ""
}

##############################################################################
# frequentVisitors
# Lists the top 10 IP addresses by total request count.
##############################################################################
frequentVisitors() {
    echo ""
    echo "=== Frequent Visitors (Top 10 IPs) ==="
    if [[ ! -f "$LOG" ]]; then
        echo "[!] Log not found: $LOG"
        return 1
    fi

    awk '{print $1}' "$LOG" \
        | sort \
        | uniq -c \
        | sort -rn \
        | head -10 \
        | awk '{printf "  %-6s requests from %s\n", $1, $2}'
    echo ""
}

##############################################################################
# suspiciousVisitors
# Cross-references client IPs against ioc.txt (one IP/hostname per line).
# Any log entry whose source IP matches an IOC entry is flagged.
##############################################################################
suspiciousVisitors() {
    echo ""
    echo "=== Suspicious Visitors (IOC Match) ==="

    if [[ ! -f "$IOC_FILE" ]]; then
        echo "[!] IOC file not found: $IOC_FILE"
        echo "    Create it manually — one IP or hostname per line:"
        echo "    echo '10.0.17.99' >> ./ioc.txt"
        echo "    echo '192.168.1.55' >> ./ioc.txt"
        return 1
    fi

    if [[ ! -f "$LOG" ]]; then
        echo "[!] Log not found: $LOG"
        return 1
    fi

    local found=0
    while IFS= read -r ioc; do
        [[ -z "$ioc" || "$ioc" == \#* ]] && continue
        matches=$(grep -c "^${ioc} " "$LOG" 2>/dev/null || true)
        if (( matches > 0 )); then
            echo "  [MATCH] IOC: $ioc — $matches log entries"
            grep "^${ioc} " "$LOG" | head -5 | sed 's/^/    /'
            found=$((found + 1))
        fi
    done < "$IOC_FILE"

    if (( found == 0 )); then
        echo "  No IOC matches found in log."
    fi
    echo ""
}

##############################################################################
# countingCurlAccess
# Counts curl requests per unique source IP.
##############################################################################
countingCurlAccess() {
    echo ""
    echo "=== curl Access Count by IP ==="
    if [[ ! -f "$LOG" ]]; then
        echo "[!] Log not found: $LOG"
        return 1
    fi

    grep -i 'curl' "$LOG" \
        | awk '{print $1}' \
        | sort \
        | uniq -c \
        | sort -rn \
        | awk '{printf "  %-6s requests from %s\n", $1, $2}'

    echo ""
    local total
    total=$(grep -ci 'curl' "$LOG" 2>/dev/null || echo 0)
    echo "  Total curl requests: $total"
    echo ""
}

##############################################################################
# Menu
##############################################################################
show_menu() {
    echo ""
    echo "=============================="
    echo "  Apache Log Analyzer"
    echo "  Log: $LOG"
    echo "=============================="
    echo "  1) Display only pages requested"
    echo "  2) Frequent visitors (top 10 IPs)"
    echo "  3) Suspicious visitors (IOC match)"
    echo "  4) Count curl access by IP"
    echo "  q) Quit"
    echo "=============================="
    echo -n "  Select option: "
}

main_loop() {
    while true; do
        show_menu
        read -r choice
        case "$choice" in
            1) displayOnlyPages ;;
            2) frequentVisitors ;;
            3) suspiciousVisitors ;;
            4) countingCurlAccess ;;
            q|Q) echo "Exiting."; exit 0 ;;
            *) echo "" ; echo "  [!] Invalid option: '$choice' — enter 1, 2, 3, 4, or q" ;;
        esac
    done
}

# Allow sourcing for unit testing individual functions
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_loop
fi
