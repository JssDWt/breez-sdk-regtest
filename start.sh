#!/bin/bash

set -xe

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR/boltz"
./start.sh

cd "$SCRIPT_DIR"
docker compose down
docker compose up --remove-orphans -d

set +x

source "$SCRIPT_DIR/boltz/aliases.sh"
shopt -s expand_aliases

CHECK_INTERVAL=2  
TIMEOUT_SECONDS=120 
FUNDING_UTXO_AMOUNT_BTC="0.6"
FUNDING_UTXO_AMOUNT_MSAT=60000000000 # 0.6 BTC
CHANNEL_AMOUNT_SATS=50000000 # 0.5 BTC

LSP_CONTAINER_NAME="breez-sdk-regtest-lsp-lightningd-1"

wait_for_condition() {
    local condition_cmd="$1"
    local description="$2"
    local start_time=$(date +%s)

    echo "Waiting for: $description"
    while true; do
        if eval "$condition_cmd"; then
            echo "Condition met: $description"
            return 0
        fi

        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))

        if [ $elapsed_time -ge $TIMEOUT_SECONDS ]; then
            echo "Timeout waiting for: $description"
            exit 1
        fi

        sleep $CHECK_INTERVAL
    done
}

sleep 5

wait_for_condition \
    "! docker exec $LSP_CONTAINER_NAME cln getinfo | jq -e 'has(\"warning_bitcoind_sync\") or has(\"warning_lightningd_sync\")' > /dev/null" \
    "LSP node ($LSP_CONTAINER_NAME) to sync to chain"


echo "[+] Funding $LSP_CONTAINER_NAME with 2 UTXOs..."

LSP_ADDRESS=$(docker exec $LSP_CONTAINER_NAME cln newaddr | jq -r .bech32)
if [ -z "$LSP_ADDRESS" ]; then
    echo "Error: Failed to get new address from $LSP_CONTAINER_NAME"
    exit 1
fi
echo "  LSP Address: $LSP_ADDRESS"

echo "  Sending $FUNDING_UTXO_AMOUNT_BTC BTC via alias to LSP (UTXO 1)..."
TXID1=$(bitcoin-cli-sim-client sendtoaddress "$LSP_ADDRESS" $FUNDING_UTXO_AMOUNT_BTC)
echo "    Funding TXID 1: $TXID1"
echo "  Sending $FUNDING_UTXO_AMOUNT_BTC BTC via alias to LSP (UTXO 2)..."
TXID2=$(bitcoin-cli-sim-client sendtoaddress "$LSP_ADDRESS" $FUNDING_UTXO_AMOUNT_BTC)
echo "    Funding TXID 2: $TXID2"

echo "  Mining 10 blocks via alias for confirmation..."
bitcoin-cli-sim-client -generate 10

# Wait for LSP to see the two specific confirmed funds
wait_for_condition \
    "count=\$(docker exec $LSP_CONTAINER_NAME cln listfunds | jq --argjson amount $FUNDING_UTXO_AMOUNT_MSAT '[.outputs[] | select(.status == \"confirmed\" and .amount_msat == \$amount)] | length'); [ \"\$count\" -ge 2 ]" \
    "LSP node ($LSP_CONTAINER_NAME) to detect 2 confirmed funding UTXOs of $FUNDING_UTXO_AMOUNT_MSAT msat each"

echo "  LSP On-chain Balance ($LSP_CONTAINER_NAME):"
docker exec $LSP_CONTAINER_NAME cln listfunds

echo "[+] Opening channels from $LSP_CONTAINER_NAME to Boltz nodes..."

# Get Boltz node details
echo "  Fetching Boltz node details..."
LND2_INFO_JSON=$(lncli-sim 2 getinfo)
LND2_PUBKEY=$(echo $LND2_INFO_JSON | jq -r '.identity_pubkey')
LND2_HOST="boltz-lnd-2" 
LND2_PORT="9735" 
LND2_URI="${LND2_PUBKEY}@${LND2_HOST}:${LND2_PORT}"
echo "    LND2 URI: $LND2_URI"

CLN2_INFO_JSON=$(lightning-cli-sim 2 getinfo)
CLN2_PUBKEY=$(echo $CLN2_INFO_JSON | jq -r '.id')
CLN2_HOST="boltz-cln-2" 
CLN2_PORT="9735" 
CLN2_URI="${CLN2_PUBKEY}@${CLN2_HOST}:${CLN2_PORT}"
echo "    CLN2 URI: $CLN2_URI"

if [ -z "$LND2_PUBKEY" ] || [ -z "$CLN2_PUBKEY" ]; then
    echo "Error: Failed to get pubkey for one or both Boltz nodes."
    exit 1
fi

# Connect lsp-lightningd to Boltz nodes (if not already connected)
echo "  Attempting to connect $LSP_CONTAINER_NAME to Boltz nodes..."
if ! docker exec $LSP_CONTAINER_NAME cln listpeers | jq -e --arg PK "$LND2_PUBKEY" '.peers[] | select(.id == $PK and .connected == true)' > /dev/null; then
    docker exec $LSP_CONTAINER_NAME cln connect "$LND2_PUBKEY" "$LND2_HOST" "$LND2_PORT" || echo "    Warn: Error connecting to LND2 ($LND2_URI)"
else
    echo "    Already connected to LND2."
fi
if ! docker exec $LSP_CONTAINER_NAME cln listpeers | jq -e --arg PK "$CLN2_PUBKEY" '.peers[] | select(.id == $PK and .connected == true)' > /dev/null; then
    docker exec $LSP_CONTAINER_NAME cln connect "$CLN2_PUBKEY" "$CLN2_HOST" "$CLN2_PORT" || echo "    Warn: Error connecting to CLN2 ($CLN2_URI)"
else
    echo "    Already connected to CLN2."
fi

# Wait for connections to establish
wait_for_condition "docker exec $LSP_CONTAINER_NAME cln listpeers | jq -e --arg PK '$LND2_PUBKEY' '.peers[] | select(.id == \$PK and .connected == true)' > /dev/null" "LSP ($LSP_CONTAINER_NAME) to connect to LND2 ($LND2_PUBKEY)"
wait_for_condition "docker exec $LSP_CONTAINER_NAME cln listpeers | jq -e --arg PK '$CLN2_PUBKEY' '.peers[] | select(.id == \$PK and .connected == true)' > /dev/null" "LSP ($LSP_CONTAINER_NAME) to connect to CLN2 ($CLN2_PUBKEY)"

# Open channels (0.5 BTC each)
echo "  Opening channel to LND2 ($LND2_URI) for $CHANNEL_AMOUNT_SATS sats..."
docker exec $LSP_CONTAINER_NAME cln fundchannel "$LND2_PUBKEY" $CHANNEL_AMOUNT_SATS

echo "  Opening channel to CLN2 ($CLN2_URI) for $CHANNEL_AMOUNT_SATS sats..."
docker exec $LSP_CONTAINER_NAME cln fundchannel "$CLN2_PUBKEY" $CHANNEL_AMOUNT_SATS

sleep 5

# confirm channels
echo "  Mining 12 blocks via alias for channel confirmation..."
bitcoin-cli-sim-client -generate 6

# Wait for channels to become active
wait_for_condition \
    "docker exec $LSP_CONTAINER_NAME cln listpeerchannels $LND2_PUBKEY | jq -e '.channels[]? | select(.state == \"CHANNELD_NORMAL\")' > /dev/null" \
    "Channel with LND2 ($LND2_PUBKEY) to become active (CHANNELD_NORMAL)"
wait_for_condition \
    "docker exec \"$LSP_CONTAINER_NAME\" cln listpeerchannels \"$CLN2_PUBKEY\" | jq -e '.channels[]? | select(.state == \"CHANNELD_NORMAL\")' > /dev/null" \
    "Channel with LND2 ($LND2_PUBKEY) to become active (CHANNELD_NORMAL)"

echo "  LSP Channel List ($LSP_CONTAINER_NAME):"
docker exec $LSP_CONTAINER_NAME cln listchannels

echo "[+] Setup complete."