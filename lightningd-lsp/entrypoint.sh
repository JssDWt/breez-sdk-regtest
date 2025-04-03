#!/usr/bin/env bash

set -m
lightningd "$@" &

echo "Core-Lightning starting"
while read -r i; do if [ "$i" = "lightning-rpc" ]; then break; fi; done \
    < <(inotifywait -e create,open --format '%f' --quiet "/data/.lightning/regtest" --monitor)

while lightning-cli --regtest --lightning-dir /data/.lightning getinfo | jq -e 'has("warning_bitcoind_sync") or has("warning_lightningd_sync")' > /dev/null
do
    echo "Waiting for node to sync to chain"
    sleep 1
done

outputcount=$(lightning-cli --regtest --lightning-dir /data/.lightning listfunds | jq '.outputs | length')
while [ "$outputcount" -lt 50 ]
do
    echo "Sending 1M sat to the internal wallet"
    addr=$(lightning-cli --regtest --lightning-dir /data/.lightning newaddr | jq '.bech32' | tr -d '"')
    url="miner:8888/send?address=${addr}&amount=1000000"
    echo "Querying miner for funds: $url"
    curl -i -H "Accept: application/json" "$url"
    outputcount=$(($outputcount + 1))
done

while lightning-cli --regtest --lightning-dir /data/.lightning getinfo | jq -e 'has("warning_bitcoind_sync") or has("warning_lightningd_sync")' > /dev/null
do
    echo "Waiting for node to sync to chain"
    sleep 1
done

pubkey=$(lightning-cli --regtest --lightning-dir /data/.lightning getinfo | jq .id | tr -d '"')
echo "Node has pubkey: $pubkey"
echo $pubkey > /data/.lightning/regtest/pubkey

fg %-