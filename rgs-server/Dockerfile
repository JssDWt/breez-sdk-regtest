ARG USER=rgs
ARG VERSION=2b60838881a9b4fbd795c813434d319ecf6ef604
ARG REPOSITORY=https://github.com/lightningdevkit/rapid-gossip-sync-server.git


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

WORKDIR /app/

COPY --from=downloader /source/ ./

RUN cargo install --path .


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN adduser --disabled-password \
            --home "/data" \
            --gecos "" \
            "$USER"

USER $USER

RUN mkdir -p "/data/.rgs"

VOLUME /data/.rgs/

ENV RAPID_GOSSIP_SYNC_SERVER_CACHES_PATH=/data/.rgs

COPY --from=builder /usr/local/cargo/bin/rapid-gossip-sync-server /usr/local/bin/

ENTRYPOINT ["rapid-gossip-sync-server"]