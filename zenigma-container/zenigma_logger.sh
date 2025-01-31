#!/bin/bash

LOG_FILE="/app/zenigma.log"

while true; do
    echo "$(date +"%Y-%m-%d %H:%M:%S") Merhaba Zenigma!" >> "$LOG_FILE"
    sleep 15
done

