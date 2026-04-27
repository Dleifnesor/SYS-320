#!/bin/bash

# log_parser.bash
# Displays only IP address and page name for records showing access to page2.html
# Reads from /var/log/apache2/access.log
#
# Pipeline breakdown:
#   cat        - read the log file
#   grep       - filter to only page2.html entries
#   cut -d" "  - split by space, grab field 1 (IP) and field 7 (page path)
#   tr -d "["  - strip any leftover bracket characters

cat /var/log/apache2/access.log | \
    grep "page2.html" | \
    cut -d" " -f1,7 | \
    tr -d "["
