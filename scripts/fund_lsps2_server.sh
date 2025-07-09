#!/usr/bin/env bash

set -m
set -e

echo "Funding lsps2-server"
addr=$(docker compose exec alice-lightningd curl --no-progress-meter lsps2-server:9736/newaddr)
url="miner:8888/send?address=${addr}&amount=10000000"
docker compose exec alice-lightningd curl --no-progress-meter -H "Accept: application/json" "$url"
echo "Telling miner to mine 7 blocks"
docker compose exec alice-lightningd curl --no-progress-meter -H "Accept: application/json" "miner:8888/mine?blocks=7"
