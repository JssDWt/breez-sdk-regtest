default: docker-bitcoind docker-breez-server docker-lightningd-alice docker-lightningd-lsp docker-lspd docker-miner docker-rgs

docker-bitcoind:
	docker build -t bitcoind -f bitcoind/Dockerfile bitcoind

docker-breez-server:
	docker build -t breez-server -f breez-server/Dockerfile breez-server

docker-lightningd: docker-bitcoind
	docker build -t lightningd -f lightningd/Dockerfile lightningd

docker-lightningd-alice:
	docker build -t lightningd-alice -f lightningd-alice/Dockerfile lightningd-alice

docker-lightningd-greenlight: docker-lightningd
	docker build -t lightningd-greenlight -f lightningd-greenlight/Dockerfile lightningd-greenlight

docker-lightningd-lsp: docker-lightningd
	docker build -t lightningd-lsp -f lightningd-lsp/Dockerfile lightningd-lsp

docker-lspd:
	docker build -t lspd -f lspd/Dockerfile lspd

docker-miner:
	docker build -t miner -f miner/Dockerfile miner

docker-scheduler:
	docker build -t greenlight-scheduler -f greenlight-scheduler/Dockerfile greenlight-scheduler

docker-rgs:
	docker build -t rgs-server -f rgs/Dockerfile rgs
