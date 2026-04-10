#!/usr/bin/env bash
# reading_tables.sh
# SYS-320-01 | Reading Tables
# Scrapes two sensor tables from a target web page and merges them into one output.
# Requires: curl, python3 (with html.parser — stdlib, no pip needed)
# Usage: ./reading_tables.sh [url]

set -euo pipefail

TARGET_URL="${1:-http://10.0.17.6/Assignment.html}"

usage() {
    echo "Usage: $0 [url]"
    echo "  url  - page hosting the two sensor tables (default: http://10.0.17.6/Assignment.html)"
    exit 1
}

check_deps() {
    for dep in curl python3; do
        if ! command -v "$dep" &>/dev/null; then
            echo "[!] Missing dependency: $dep"
            exit 1
        fi
    done
}

fetch_and_merge() {
    echo "[*] Fetching: $TARGET_URL"
    HTML=$(curl -s --max-time 15 "$TARGET_URL")
    if [[ -z "$HTML" ]]; then
        echo "[!] No response from $TARGET_URL"
        exit 1
    fi

    echo "$HTML" | python3 - <<'PYEOF'
import sys
from html.parser import HTMLParser

class TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tables = []
        self.current_table = []
        self.current_row = []
        self.current_cell = []
        self.in_cell = False
        self.in_table = False

    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            self.in_table = True
            self.current_table = []
        elif tag in ('tr',) and self.in_table:
            self.current_row = []
        elif tag in ('td', 'th') and self.in_table:
            self.in_cell = True
            self.current_cell = []

    def handle_endtag(self, tag):
        if tag == 'table':
            self.tables.append(self.current_table[:])
            self.current_table = []
            self.in_table = False
        elif tag == 'tr' and self.in_table:
            if self.current_row:
                self.current_table.append(self.current_row[:])
            self.current_row = []
        elif tag in ('td', 'th') and self.in_cell:
            self.current_row.append(''.join(self.current_cell).strip())
            self.current_cell = []
            self.in_cell = False

    def handle_data(self, data):
        if self.in_cell:
            self.current_cell.append(data)

html = sys.stdin.read()
parser = TableParser()
parser.feed(html)

tables = parser.tables

if len(tables) < 2:
    print(f"[!] Only found {len(tables)} table(s) — expected 2")
    sys.exit(1)

t1, t2 = tables[0], tables[1]

# Determine max rows across both tables
max_rows = max(len(t1), len(t2))

# Determine column widths for aligned output
def col_widths(table):
    if not table:
        return []
    ncols = max(len(r) for r in table)
    widths = [0] * ncols
    for row in table:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))
    return widths

w1 = col_widths(t1)
w2 = col_widths(t2)

def fmt_row(row, widths):
    cells = []
    for i, w in enumerate(widths):
        val = row[i] if i < len(row) else ''
        cells.append(val.ljust(w))
    return ' | '.join(cells)

def separator(widths):
    return '-+-'.join('-' * w for w in widths)

print("=== Merged Sensor Tables ===")
print()

# Header: first row of each table side by side
if t1 and t2:
    hdr1 = fmt_row(t1[0], w1)
    hdr2 = fmt_row(t2[0], w2)
    print(f"{hdr1}   |   {hdr2}")
    print(f"{separator(w1)}   +   {separator(w2)}")

# Data rows
for i in range(1, max_rows):
    r1 = t1[i] if i < len(t1) else []
    r2 = t2[i] if i < len(t2) else []
    row1_str = fmt_row(r1, w1) if r1 else ' ' * sum(w1 + [3] * (len(w1) - 1))
    row2_str = fmt_row(r2, w2) if r2 else ''
    print(f"{row1_str}   |   {row2_str}")

print()
PYEOF
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && usage

check_deps
fetch_and_merge
