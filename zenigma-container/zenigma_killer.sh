#!/bin/bash

LOG_FILE="/app/zenigma.log"
PID_FILE="/app/zenigma_logger.pid"
KILLER_LOG="/app/killer.log"

if [[ -f "$LOG_FILE" ]]; then
    LINE_COUNT=$(wc -l < "$LOG_FILE")
else
    LINE_COUNT=0
fi

if [[ "$LINE_COUNT" -ge 20 ]]; then
    if [[ -f "$PID_FILE" ]]; then
        kill -9 $(cat "$PID_FILE") 2>/dev/null
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Logger process terminated. Line count: $LINE_COUNT" >> "$KILLER_LOG"
        rm -f "$PID_FILE"
    fi

    rm -f "$LOG_FILE"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - zenigma.log deleted." >> "$KILLER_LOG"

    nohup bash /app/zenigma_logger.sh &> /dev/null &
    echo $! > "$PID_FILE"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Logger restarted." >> "$KILLER_LOG"
fi

