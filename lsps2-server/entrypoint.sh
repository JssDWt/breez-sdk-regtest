#!/usr/bin/env bash

set -e
set -m

echo "[ENTRYPOINT] Waiting for electrs to be ready..."
while true; do
    if curl --no-progress-meter --max-time 1 http://electrs:30000/blocks/tip/height > /dev/null 2>&1; then
        echo "[ENTRYPOINT] Electrs is ready"
        break
    else
        echo "[ENTRYPOINT] Electrs is not ready yet, retrying in 1 second..."
        sleep 1
    fi
done

lsps2-server &
LSPS2_PID=$!

cleanup() {
    echo "[ENTRYPOINT] Received SIGTERM, forwarding to lsps2-server (PID: $LSPS2_PID)"
    kill -TERM $LSPS2_PID
    wait $LSPS2_PID
    exit 0
}
trap cleanup SIGTERM

echo "[ENTRYPOINT] Waiting for lsps2-server to be ready..."
while true; do
    if addr=$(curl --no-progress-meter --max-time 1 localhost:9736/newaddr 2>/dev/null); then
        echo "[ENTRYPOINT] Successfully got newaddr: $addr"
        break
    else
        echo "[ENTRYPOINT] lsps2-server not ready yet, retrying in 1 second..."
        sleep 1
    fi
done

echo "[ENTRYPOINT] Funding lsps2-server"
url="miner:8888/send?address=${addr}&amount=10000000"
funding_response=$(curl --no-progress-meter -H "Accept: application/json" "$url")
echo "[ENTRYPOINT] Funding response: $funding_response"

echo "[ENTRYPOINT] Syncing wallets"
sync_response=$(curl --no-progress-meter "localhost:9736/sync")
echo "[ENTRYPOINT] Sync response: $sync_response"

wait $LSPS2_PID
