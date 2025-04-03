#!/usr/bin/env bash

set -m
lightningd "$@" &

echo "Core-Lightning starting"
while read -r i; do if [ "$i" = "lightning-rpc" ]; then break; fi; done \
    < <(inotifywait -e create,open --format '%f' --quiet "/data/.lightning/regtest" --monitor)

outputcount=$(lightning-cli --regtest listfunds | jq '.outputs | length')
while [ "$outputcount" -lt 50 ]
do
    echo "Sending 1M sat to the internal wallet"
    addr=$(lightning-cli --regtest newaddr | jq '.bech32' | tr -d '"')
    url="miner:8888/send?address=${addr}&amount=1000000"
    echo "Querying miner for funds: $url"
    curl -i -H "Accept: application/json" "$url"
    outputcount=$(($outputcount + 1))
done

fg %-