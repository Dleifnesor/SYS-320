#!/bin/bash

# page_count.bash
# Function: pageCount
# Returns how many times each page was accessed from apache2 access log

function pageCount {
    # Extract field 7 (page/request path) from each log line,
    # sort the list, then count unique occurrences with uniq -c
    cat /var/log/apache2/access.log | \
        cut -d" " -f7 | \
        sort | \
        uniq -c
}

# Call the function and store result
result=$(pageCount)

# Print the result
echo "$result"
