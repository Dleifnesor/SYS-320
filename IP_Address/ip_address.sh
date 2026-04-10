#!/usr/bin/env bash
# ip_address.sh
# SYS-320-01 | IP Address
# Extracts the primary non-loopback IPv4 address from `ip addr` output.
# Deliverable: run this script and screenshot the output.

set -euo pipefail

# Method 1: grep + awk pipeline
# Extracts the inet line for the default route interface, strips the CIDR suffix.
ip_via_awk() {
    ip addr show \
        | grep 'inet ' \
        | grep -v '127.0.0.1' \
        | awk '{print $2}' \
        | cut -d'/' -f1 \
        | head -1
}

# Method 2: route-aware — finds IP on the interface used for the default route
ip_via_route() {
    IFACE=$(ip route | awk '/default/ {print $5}' | head -1)
    ip addr show "$IFACE" \
        | grep 'inet ' \
        | awk '{print $2}' \
        | cut -d'/' -f1
}

# Method 3: pure awk one-liner (matches assignment style)
ip_awk_oneliner() {
    ip addr \
        | awk '/inet / && !/127.0.0.1/ {gsub(/\/[0-9]+/, "", $2); print $2; exit}'
}

echo "=== IP Address Extraction ==="
echo ""
echo "Method 1 (grep + awk + cut):"
ip_via_awk

echo ""
echo "Method 2 (route-aware):"
ip_via_route

echo ""
echo "Method 3 (awk one-liner):"
ip_awk_oneliner

echo ""
echo "=== Full ip addr output for reference ==="
ip addr
