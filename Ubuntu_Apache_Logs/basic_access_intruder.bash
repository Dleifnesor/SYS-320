#!/bin/bash

# basic_access_intruder.bash
# Accesses the web server 20 times in a row using curl
# Usage: bash basic_access_intruder.bash

IP="10.0.17.100"   # replace with your actual IP from ip addr

for i in {1..20}
do
    curl -s http://$IP/page2.html > /dev/null
    echo "Request $i sent to http://$IP/page2.html"
done
