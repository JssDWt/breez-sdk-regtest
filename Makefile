default: docker-bitcoind docker-breez-server docker-lightningd docker-lightningd-greenlight docker-lightningd-lsp docker-lspd docker-scheduler

docker-bitcoind:
	docker build -t bitcoind -f bitcoind/Dockerfile bitcoind

docker-breez-server:
	docker build -t breez-server -f breez-server/Dockerfile breez-server

docker-lightningd: docker-bitcoind
	docker build -t lightningd -f lightningd/Dockerfile lightningd

docker-lightningd-greenlight: docker-lightningd
	docker build -t lightningd-greenlight -f lightningd-greenlight/Dockerfile lightningd-greenlight

docker-lightningd-lsp: docker-lightningd
	docker build -t lightningd-lsp -f lightningd-lsp/Dockerfile lightningd-lsp

docker-lspd:
	docker build -t lspd -f lspd/Dockerfile lspd

docker-scheduler:
	docker build -t greenlight-scheduler -f greenlight-scheduler/Dockerfile greenlight-scheduler
