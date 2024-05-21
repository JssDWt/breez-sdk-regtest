## LSPD
- initialize with opening fee params
- fund with plenty of utxos
- make lspd start after lightningd's grpc certificates are initialized

## Bitcoind
- add a miner that
  - initially mines 101 blocks
  - periodically mines blocks (potentially?)
- add a way to fund other nodes

## Alice
- add a 'remote node' that can pay invoices and receive payments
  - this node is connected to the LSP lightning node with a big fat public channel

## Swapper
- add a swapper connected to the LSP with a big fat channel

## Breez server
- connect it to the swapper
- connect it to LSPD
- return internal mempool.space url

## Greenlight
- The lightning container cannot find the certficates yet
- The scheduler should stop on shutdown signal

## Mempool.space
- connect mempool.space to bitcoind

## Boltz
- inspiration here: https://github.com/BoltzExchange/legend-regtest-enviroment
