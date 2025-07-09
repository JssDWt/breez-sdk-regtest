#!/usr/bin/env bash

set -m
set -e

echo "Querying lsps2-server"
id=$(docker compose exec alice-lightningd curl --no-progress-meter lsps2-server:9736/getid)
address=$id@lsps2-server:9735
echo "Connecting to $address"
docker compose exec alice-lightningd cln connect $address
echo "Funding a channel to lsps2-server"
docker compose exec alice-lightningd cln fundchannel id=$id amount=10000000sat push_msat=5000000sat
echo "Telling miner to mine 7 blocks"
docker compose exec alice-lightningd curl --no-progress-meter -H "Accept: application/json" "miner:8888/mine?blocks=7"
