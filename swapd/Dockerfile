# $USER name to be used in the `final` image
ARG USER=swapd
# v25.02
ARG VERSION=80cc1e3f4f80afbffaa95e31f63d91bdb2d85ea9
ARG REPOSITORY=https://github.com/breez/swapd.git


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


FROM rust:1.86-slim-bookworm AS builder

USER root

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        build-essential \
        libssl-dev \
        pkg-config \
        protobuf-compiler

WORKDIR /app/
COPY  --from=downloader /source/  ./

RUN cargo install --path ./swapd
RUN cargo install --path ./swap-cli


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        ca-certificates \
        libssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password \
            --home "/data/" \
            --gecos "" \
            "$USER"

USER $USER

# Swapd external api port
EXPOSE 19846

COPY --from=builder /usr/local/cargo/bin/swapd /usr/local/bin/
COPY --from=builder /usr/local/cargo/bin/swap-cli /usr/local/bin/

ENTRYPOINT ["swapd"]
