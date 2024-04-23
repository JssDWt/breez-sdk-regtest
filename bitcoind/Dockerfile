# $USER name, and data $DIR to be used in the `final` image
ARG USER=bitcoind
ARG DIR=/data

FROM alpine:3.19.1 AS builder

RUN apk add --no-cache \
        gnupg \
        git \
        autoconf \
        automake \
        boost-dev \
        sqlite-dev \
        build-base \
        chrpath \
        file \
        libevent-dev \
        libressl \
        libtool \
        linux-headers \
        zeromq-dev

# Guix Builder Keys: https://github.com/bitcoin-core/guix.sigs/tree/main/builder-keys
# curl -s "https://api.github.com/repos/bitcoin-core/guix.sigs/contents/builder-keys" | jq -r '.[].download_url'
ENV BUILDER_KEYS 982A193E3CE0EED535E09023188CBB2648416AD5 101598DC823C1B5F9A6624ABA5E0907A0380E6C3 9EDAFF80E080659604F4A76B2EBB056FD847F8A7 \
                 ED9BDF7AD6A55E232E84524257FF9BDBCC301009 A8FC55F3B04BA3146F3492E79303B33A305224CB 152812300785C96444D3334D17565732E08E5E41 \
                 0AD83877C1F0CD1EE9BD660AD7CC770B81FD22A8 C060A6635913D98A3587D7DB1C2491FFEB0EF770 590B7292695AFFA5B672CBB2E13FC145CD3F4304 \
                 948444FCE03B05BA5AB0591EC37B1C1D44C786EE E777299FC265DD04793070EB944D35F9AC3DB76A 6B002C6EA3F91B1B0DF0C9BC8F617F1200A6D25C \
                 F4FC70F07310028424EFC20A8E4256593F177720 D1DBF2C4B96F2DEBF4C16654410108112E7EA81F 287AE4CA1187C68C08B49CB2D11BD4F33F1DB499 \
                 616516B8EB6ED02882FC4A7A8ADCB558C4F33D65 71A3B16735405025D447E8F274810B012346C9A6 2F78ACF677029767C8736F13747A7AE2FB0FD25B \
                 133EAC179436F14A5CF1B794860FEB804E669320 9ED99C7A355AE46098103E74476E74C8529A9006 6A8F9C266528E25AEB1D7731C2371D91CB716EA7 \
                 28E72909F1717FE9607754F8A7BEB2621678D37D 67AA5B46E7AF78053167FE343B8F814A784218F8 79D00BAC68B56D422F945A8F8E3A8F3247DBCBBF \
                 C388F6961FB972A95678E327F62711DBDCA8AE56 9DEAE0DC7063249FB05474681E4AED62986CD25D

RUN gpg --keyserver keyserver.ubuntu.com --recv-keys $BUILDER_KEYS
RUN git clone  -b "v26.1"  --depth=1  https://github.com/bitcoin/bitcoin.git  "/bitcoin/"
RUN cd "/bitcoin/" && \
    git verify-tag "v26.1"

WORKDIR /bitcoin/
RUN ./autogen.sh

RUN ./configure LDFLAGS=-L/opt/db4/lib/ CPPFLAGS=-I/opt/db4/include/ \
    CXXFLAGS="-O2" \
    --prefix="/opt/bitcoin" \
    --disable-man \
    --disable-shared \
    --disable-ccache \
    --disable-tests \
    --enable-static \
    --enable-reduce-exports \
    --without-gui \
    --without-libs \
    --with-utils \
    --with-sqlite=yes \
    --with-daemon

RUN make -j$(( $(nproc) + 1 ))
RUN make install

# List installed binaries pre-strip & strip them
RUN ls -lh "/opt/bitcoin/bin/"
RUN strip -v "/opt/bitcoin/bin/bitcoin"*

# List installed binaries post-strip & print their checksums
RUN ls -lh "/opt/bitcoin/bin/"
RUN sha256sum "/opt/bitcoin/bin/bitcoin"*


FROM alpine:3.19.1 AS final

ARG USER
ARG DIR

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN apk add --no-cache \
        libevent \
        libsodium \
        libstdc++ \
        libzmq \
        sqlite-libs

COPY  --from=builder /opt/bitcoin/bin/bitcoin*  /usr/local/bin/

RUN adduser --disabled-password \
            --home "$DIR/" \
            --gecos "" \
            "$USER"

USER $USER

# Prevents `VOLUME $DIR/.bitcoind/` being created as owned by `root`
RUN mkdir -p "$DIR/.bitcoin/"

# Expose volume containing all `bitcoind` data
VOLUME $DIR/.bitcoin/

# REST interface
EXPOSE 8080

# P2P network (mainnet, testnet & regnet respectively)
EXPOSE 8333 18333 18444

# RPC interface (mainnet, testnet & regnet respectively)
EXPOSE 8332 18332 18443

# ZMQ ports (for transactions & blocks respectively)
EXPOSE 28332 28333

ENTRYPOINT ["bitcoind"]

CMD ["-zmqpubrawblock=tcp://0.0.0.0:28332", "-zmqpubrawtx=tcp://0.0.0.0:28333"]