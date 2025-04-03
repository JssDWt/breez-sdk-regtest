ARG USER=cln
ARG VERSION=157208cc771be99a7744d100564c5a44afa41b8f
ARG REPOSITORY=https://github.com/JssDWt/greenlight.git

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


FROM rust:1.78-slim-bookworm AS plugin-builder

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        protobuf-compiler

WORKDIR /app/

COPY --from=downloader /source/ ./

WORKDIR /app/libs/gl-plugin

RUN cargo build --release

FROM rust:1.78-slim-bookworm AS signerproxy-builder

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        protobuf-compiler

RUN rustup component add rustfmt

WORKDIR /app/

COPY --from=downloader /source/ ./

WORKDIR /app/libs/gl-signerproxy

RUN cargo build --release


FROM lightningd AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

USER root

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

USER $USER

COPY --from=plugin-builder /app/target/release/gl-plugin /usr/local/bin/
COPY --from=signerproxy-builder /app/target/release/gl-signerproxy /usr/local/bin/

ENTRYPOINT ["/entrypoint.sh"]