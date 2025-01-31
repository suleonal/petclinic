#!/bin/bash

nohup bash /app/zenigma_logger.sh &> /dev/null &
echo $! > /app/zenigma_logger.pid

while true; do
    bash /app/zenigma_killer.sh
    sleep 300
done

