#!/usr/bin/env bash

set -m
lightningd "$@" &

echo "Core-Lightning starting"
while read -r i; do if [ "$i" = "lightning-rpc" ]; then break; fi; done \
    < <(inotifywait -e create,open --format '%f' --quiet "/data/.lightning/regtest" --monitor)

echo "Core-Lightning generating keys and certificates"
if [ ! -f "/data/.lightning/regtest/client-key.pem" ]; then
    while read -r i; do if [ "$i" = "client-key.pem" ]; then break; fi; done \
        < <(inotifywait -e create,open --format '%f' --quiet "/data/.lightning/regtest" --monitor)
fi
echo "Changing permissions for /data/.lightning/regtest/client-key.pem"
chmod a+r /data/.lightning/regtest/client-key.pem

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

cln_lsp_id=$(cat /data/.lightning-lsp/regtest/pubkey)
lightning-cli --regtest --lightning-dir /data/.lightning connect "$cln_lsp_id" lsp-lightningd

lsps2_id=$(curl --no-progress-meter lsps2-server:9736/getid)
lightning-cli --regtest --lightning-dir /data/.lightning connect "$lsps2_id" lsps2-server 9735

channelcount=$(lightning-cli --regtest --lightning-dir /data/.lightning listpeerchannels $cln_lsp_id | jq '.channels | length')
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

	echo "Creating channel to peer $cln_lsp_id"
    lightning-cli --regtest --lightning-dir /data/.lightning fundchannel id="$cln_lsp_id" amount=100000000sat push_msat=50000000sat

    echo "Telling miner to mine 7 blocks"
    curl -i -H "Accept: application/json" "miner:8888/mine?blocks=7"
fi

channelcount=$(lightning-cli --regtest --lightning-dir /data/.lightning listpeerchannels $lsps2_id | jq '.channels | length')
if [ "$channelcount" -lt 1 ]
then
	echo "Creating channel to peer $lsps2_id"
    lightning-cli --regtest --lightning-dir /data/.lightning fundchannel id="$lsps2_id" amount=100000000sat push_msat=50000000sat

    echo "Telling miner to mine 7 blocks"
    curl -i -H "Accept: application/json" "miner:8888/mine?blocks=7"
fi


fg %-
