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
    url="miner:8888/send?address=${addr}&amount=10000000"
    echo "Querying miner for funds: $url"
    curl -i -H "Accept: application/json" "$url"
    outputcount=$(($outputcount + 1))
done

until [ -f "/data/.lightning-lsp/regtest/pubkey" ]
do
    echo "Waiting for lsp to dump pubkey"
    sleep 1
done

lightning-cli --regtest --lightning-dir /data/.lightning connect "$lsp_id" lsp-lightningd

channelcount=$(lightning-cli --regtest --lightning-dir /data/.lightning listpeerchannels | jq '.channels | length')
if [ "$channelcount" -lt 1 ]
then
    echo "Telling miner to mine 6 blocks"
    curl -i -H "Accept: application/json" "miner:8888/mine?blocks=6"

    while lightning-cli --regtest --lightning-dir /data/.lightning getinfo | jq -e 'has("warning_bitcoind_sync") or has("warning_lightningd_sync")' > /dev/null
    do
        echo "Waiting for node to sync to chain"
        sleep 1
    done

    while [ $(lightning-cli --regtest --lightning-dir /data/.lightning listfunds | jq '[.outputs[] | select(.status == "confirmed")] | length') -lt 20 ]
    do
        echo "Waiting for 20 outputs to be confirmed"
        sleep 1
    done
    lsp_id=$(cat /data/.lightning-lsp/regtest/pubkey)
    echo "Creating channel to peer"
    
    lightning-cli --regtest --lightning-dir /data/.lightning fundchannel id="$lsp_id" amount=100000000sat push_msat=50000000msat

    echo "Telling miner to mine 7 blocks"
    curl -i -H "Accept: application/json" "miner:8888/mine?blocks=7"
fi

fg %-