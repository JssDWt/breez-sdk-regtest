docker-all: docker-bitcoind docker-breez-server docker-lightningd docker-lspd docker-lightningd-lsp

docker-bitcoind:
	docker build -t bitcoind -f bitcoind/Dockerfile .

docker-breez-server:
	docker build -t breez-server -f breez-server/Dockerfile .

docker-lightningd: docker-bitcoind
	docker build -t lightningd -f lightningd/Dockerfile .

docker-lspd:
	docker build -t lspd -f lspd/Dockerfile .

docker-lightningd-lsp: docker-lightningd
	docker build -t lightningd-lsp -f lightningd-lsp/Dockerfile .
