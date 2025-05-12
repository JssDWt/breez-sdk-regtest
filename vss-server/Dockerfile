ARG USER=vss
ARG VERSION=c54b2c30589c252a608594e299a58cf72ada763e
ARG REPOSITORY=https://github.com/lightningdevkit/vss-server.git


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

RUN cargo install --path rust/server


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN adduser --disabled-password \
            --home "/data" \
            --gecos "" \
            "$USER"

USER $USER

COPY --from=builder /usr/local/cargo/bin/server /usr/local/bin/

ENTRYPOINT ["server"]