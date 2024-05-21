# $USER name to be used in the `final` image
ARG USER=bitcoind
# v26.1
ARG VERSION=0b4aa31c34b239ec7da36760a2670792184c3ba8
ARG REPOSITORY=https://github.com/bitcoin/bitcoin.git


FROM debian:bookworm-slim AS downloader

ARG VERSION
ARG REPOSITORY

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        ca-certificates \
        git

WORKDIR /source/

RUN git init && \
    git remote add origin "$REPOSITORY" && \
    git fetch --depth 1 origin "$VERSION" && \
    git checkout FETCH_HEAD


FROM debian:bookworm-slim AS builder

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        build-essential \
        libtool \
        autotools-dev \
        automake \
        pkg-config \
        bsdmainutils \
        python3 \
        libevent-dev \
        libboost-dev \
        libsqlite3-dev \
        libzmq3-dev

WORKDIR /app/
COPY --from=downloader /source/ ./

RUN ./autogen.sh

RUN ./configure \
    --prefix="/opt/bitcoin" \
    --disable-ccache \
    --disable-tests \
    --without-gui \
    --with-sqlite=yes

RUN make -j$(nproc) && \
    make install


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        libevent-2.1-7 \
        libevent-pthreads-2.1-7 \
        libsqlite3-0 \
        libzmq5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/bitcoin/ /usr/local/

RUN adduser --disabled-password \
            --home "/data" \
            --gecos "" \
            "$USER"

USER $USER

# Prevents `VOLUME /data/.bitcoin/` being created as owned by `root`
RUN mkdir -p "/data/.bitcoin/"

# Expose volume containing all `bitcoin` data
VOLUME /data/.bitcoin/

# REST interface
EXPOSE 8080

# P2P network (mainnet, testnet & regtest respectively)
EXPOSE 8333 18333 18444

# RPC interface (mainnet, testnet & regtest respectively)
EXPOSE 8332 18332 18443

# ZMQ ports (for transactions & blocks respectively)
EXPOSE 28332 28333

ENTRYPOINT ["bitcoind"]

CMD ["-zmqpubrawblock=tcp://0.0.0.0:28332", "-zmqpubrawtx=tcp://0.0.0.0:28333"]