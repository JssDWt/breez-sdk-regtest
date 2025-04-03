# $USER name to be used in the `final` image
ARG USER=cln
# v25.02
ARG VERSION=427c4c5ce0496795d6361ffc885010298bceff10
ARG REPOSITORY=https://github.com/ElementsProject/lightning.git


FROM debian:bookworm-slim AS downloader

ARG VERSION
ARG REPOSITORY

WORKDIR /source/

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        ca-certificates \
        git

RUN git init && \
    git remote add origin "$REPOSITORY" && \
    git fetch --depth 1 origin "$VERSION" && \
    git checkout FETCH_HEAD


FROM debian:bookworm-slim AS builder

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        curl \
        ca-certificates \
        jq \
        autoconf \
        automake \
        build-essential \
        git \
        libtool \
        libsqlite3-dev \
        python3 \
        python3-mako \
        python3-pip \
        net-tools \
        zlib1g-dev \
        libsodium-dev \
        gettext \
        protobuf-compiler

RUN pip3 install --upgrade pip --break-system-packages && \
    pip3 install grpcio-tools --break-system-packages

USER root
ENV RUST_PROFILE=release
ENV PATH=$PATH:/root/.cargo/bin/
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN rustup toolchain install stable \
    --component rustfmt \
    --allow-downgrade \
    --profile minimal

WORKDIR /app/
COPY  --from=downloader /source/  ./
COPY --from=bitcoind /usr/local/bin/bitcoin-cli /usr/local/bin/

RUN ./configure \
        --prefix="/opt/lightning" \
        --enable-static && \
    make && \
    make install


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        inotify-tools \
        libevent-2.1-7 \
        libsodium-dev \
        python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password \
            --home "/data/" \
            --gecos "" \
            "$USER"

USER $USER

# Prevents `VOLUME /data/.lightning/` being created as owned by `root`
RUN mkdir -p "/data/.lightning/regtest"

# Expose volume containing all `lightningd` data
VOLUME /data/.lightning/

# Lightning P2P port
EXPOSE 19846

COPY --from=bitcoind /usr/local/bin/bitcoin-cli /usr/local/bin/
COPY --from=builder /opt/lightning/ /usr/local/

ENTRYPOINT ["lightningd"]

CMD [ \
    "--lightning-dir='/data/.lightning'" \
]