#!/usr/bin/env bash
# ip_listing.sh
# SYS-320-01 | IP Listing
# Takes a /24 network prefix and lists all 254 host addresses.
# Usage: ./ip_listing.sh 10.0.17

set -euo pipefail

usage() {
    echo "Usage: $0 <network_prefix>"
    echo "  network_prefix  - First three octets of a /24 (e.g., 10.0.17)"
    echo ""
    echo "Example:"
    echo "  $0 10.0.17"
    echo "  Output: 10.0.17.1 through 10.0.17.254"
    exit 1
}

validate_prefix() {
    local prefix="$1"
    # Must match X.X.X with each octet 0-255
    if ! echo "$prefix" | grep -qP '^\d{1,3}\.\d{1,3}\.\d{1,3}$'; then
        echo "[!] Invalid prefix: '$prefix'"
        echo "    Expected format: X.X.X (e.g., 192.168.1)"
        exit 1
    fi
    # Check each octet is <= 255
    IFS='.' read -r o1 o2 o3 <<< "$prefix"
    for octet in "$o1" "$o2" "$o3"; do
        if (( octet > 255 )); then
            echo "[!] Octet out of range: $octet"
            exit 1
        fi
    done
}

list_ips() {
    local prefix="$1"
    for i in $(seq 1 254); do
        echo "${prefix}.${i}"
    done
}

[[ $# -lt 1 ]] && usage

PREFIX="$1"
validate_prefix "$PREFIX"
list_ips "$PREFIX"
