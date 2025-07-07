BUILD = docker build --progress=plain -t $(1) -f $(1)/Dockerfile $(1)
SUBDIRS_WITH_SLASH := $(sort $(dir $(wildcard */.)))
SUBDIRS := $(patsubst %/,%,$(SUBDIRS_WITH_SLASH))

default: bitcoind breez-server lightningd-alice lightningd-lsp lspd lsps2-server miner rgs-server swapd vss-server

.PHONY: $(SUBDIRS)

bitcoind:
	$(call BUILD,$@)

breez-server:
	$(call BUILD,$@)

greenlight-scheduler:
	$(call BUILD,$@)

lightningd: bitcoind
	$(call BUILD,$@)

lightningd-alice: lightningd
	$(call BUILD,$@)

lightningd-greenlight: lightningd
	$(call BUILD,$@)

lightningd-lsp: lightningd
	$(call BUILD,$@)

lspd:
	$(call BUILD,$@)

lsps2-server:
	$(call BUILD,$@)

miner:
	$(call BUILD,$@)

rgs-server:
	$(call BUILD,$@)

slow-proxy:
	$(call BUILD,$@)

swapd:
	$(call BUILD,$@)

vss-server:
	$(call BUILD,$@)
