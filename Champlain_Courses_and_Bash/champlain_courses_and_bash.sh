#!/usr/bin/env bash
# champlain_courses_and_bash.sh
# SYS-320-01 | Champlain Courses and Bash
# Scrapes the Champlain course schedule HTML page and processes it
# using xmlstarlet + curl. Companion to courses.bash and assignment1.bash.
# Prereqs: sudo apt-get install xmlstarlet curl

set -euo pipefail

COURSE_URL="${1:-http://10.0.17.6/Courses2026SP.html}"
OUTPUT_FILE="${2:-courses_output.txt}"

usage() {
    echo "Usage: $0 [url] [output_file]"
    echo "  url         - Champlain course schedule page (default: http://10.0.17.6/Courses2026SP.html)"
    echo "  output_file - Where to write parsed results (default: courses_output.txt)"
    exit 1
}

check_deps() {
    for dep in curl xmlstarlet; do
        if ! command -v "$dep" &>/dev/null; then
            echo "[!] Missing: $dep"
            echo "    Install: sudo apt-get install $dep"
            exit 1
        fi
    done
}

fetch_page() {
    echo "[*] Fetching course schedule from: $COURSE_URL"
    HTML=$(curl -s --max-time 15 "$COURSE_URL")
    if [[ -z "$HTML" ]]; then
        echo "[!] No response from $COURSE_URL"
        exit 1
    fi
    echo "[*] Page fetched (${#HTML} bytes)"
}

# courses.bash equivalent: scrape course table using xmlstarlet
scrape_courses_xmlstarlet() {
    echo ""
    echo "[*] Parsing HTML table with xmlstarlet"

    # xmlstarlet requires well-formed XML/XHTML.
    # Wrap raw HTML through sed cleanup if needed, then use xpath to extract rows.
    echo "$HTML" \
        | xmlstarlet sel \
            -N html="http://www.w3.org/1999/xhtml" \
            -t \
            -m "//table//tr" \
            -v "concat(td[1], '|', td[2], '|', td[3], '|', td[4])" \
            -n \
        2>/dev/null \
        | grep -v '^|||$' \
        | tee "$OUTPUT_FILE" \
        || scrape_courses_python
}

# Fallback parser using Python stdlib (handles loose HTML that xmlstarlet rejects)
scrape_courses_python() {
    echo "[*] Falling back to Python html.parser"
    echo "$HTML" | python3 <<'PYEOF'
import sys
from html.parser import HTMLParser

class RowParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.rows = []
        self.row = []
        self.cell = []
        self.in_cell = False

    def handle_starttag(self, tag, attrs):
        if tag == 'tr': self.row = []
        elif tag in ('td','th'): self.in_cell = True; self.cell = []

    def handle_endtag(self, tag):
        if tag == 'tr':
            if self.row: self.rows.append(self.row[:])
        elif tag in ('td','th'):
            self.row.append(''.join(self.cell).strip())
            self.in_cell = False

    def handle_data(self, d):
        if self.in_cell: self.cell.append(d)

parser = RowParser()
parser.feed(sys.stdin.read())

for row in parser.rows:
    if any(cell.strip() for cell in row):
        print('|'.join(row))
PYEOF
}

# assignment1.bash equivalent: filter/process results
process_results() {
    echo ""
    echo "[*] Processing results from: $OUTPUT_FILE"
    echo ""
    echo "=== Course Listing ==="
    # Print header then data rows, formatted
    awk -F'|' 'NR==1 { printf "%-10s %-30s %-10s %-20s\n", $1, $2, $3, $4; next }
               { printf "%-10s %-30s %-10s %-20s\n", $1, $2, $3, $4 }' "$OUTPUT_FILE"

    echo ""
    echo "[*] Total rows: $(wc -l < "$OUTPUT_FILE")"
    echo ""
    echo "=== Unique Departments ==="
    awk -F'|' 'NR>1 { print $1 }' "$OUTPUT_FILE" \
        | grep -oP '^[A-Z]+' \
        | sort -u

    echo ""
    echo "=== Courses with Available Seats ==="
    awk -F'|' 'NR>1 && $4+0 > 0 { print $0 }' "$OUTPUT_FILE" \
        | head -20
}

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && usage

check_deps
fetch_page
scrape_courses_xmlstarlet
process_results
