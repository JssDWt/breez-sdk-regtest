default: bitcoind breez-server lightningd-alice lightningd-lsp lspd miner rgs-server swapd vss-server

.PHONY: bitcoind breez-server greenlight-scheduler lightningd lightningd-alice lightningd-greenlight lightningd-lsp lspd miner rgs-server swapd vss-server

bitcoind:
	docker build -t bitcoind -f bitcoind/Dockerfile bitcoind

breez-server:
	docker build -t breez-server -f breez-server/Dockerfile breez-server

greenlight-scheduler:
	docker build -t greenlight-scheduler -f greenlight-scheduler/Dockerfile greenlight-scheduler

lightningd: bitcoind
	docker build -t lightningd -f lightningd/Dockerfile lightningd

lightningd-alice: lightningd
	docker build -t lightningd-alice -f lightningd-alice/Dockerfile lightningd-alice

lightningd-greenlight: lightningd
	docker build -t lightningd-greenlight -f lightningd-greenlight/Dockerfile lightningd-greenlight

lightningd-lsp: lightningd
	docker build -t lightningd-lsp -f lightningd-lsp/Dockerfile lightningd-lsp

lspd:
	docker build -t lspd -f lspd/Dockerfile lspd

miner:
	docker build -t miner -f miner/Dockerfile miner

rgs-server:
	docker build -t rgs-server -f rgs-server/Dockerfile rgs-server

swapd:
	docker build -t swapd -f swapd/Dockerfile swapd

vss-server:
	docker build -t vss-server -f vss-server/Dockerfile vss-server
