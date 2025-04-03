# $USER name to be used in the `final` image
ARG USER=cln
ARG VERSION=c7ce06c5456e0a7fe3b14c5c83dfc1c9c433258d
ARG REPOSITORY=https://github.com/breez/lspd.git
ARG GOLANG_MIGRATE_VERSION=4.16.1

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


FROM golang:bookworm AS builder

WORKDIR /app

COPY --from=downloader /source/go.mod /source/go.sum ./

RUN go mod download

COPY --from=downloader /source/ ./

RUN make release-lspd


FROM debian:bookworm-slim AS migrate

ARG GOLANG_MIGRATE_VERSION

WORKDIR /

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        ca-certificates \
        curl \
        tar

RUN ARCH=$(uname -m); \
    case "$ARCH" in \
        aarch64) ARCH="arm64" ;; \
        x86_64)  ARCH="amd64" ;; \
        armv7l)  ARCH="armv7" ;; \
        i386)    ARCH="386" ;; \
    esac && \
    curl -L -o migrate.tar.gz "https://github.com/golang-migrate/migrate/releases/download/v${GOLANG_MIGRATE_VERSION}/migrate.linux-${ARCH}.tar.gz" && \
    tar xvzf migrate.tar.gz -C /


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN adduser --disabled-password \
            --home "/data/" \
            --gecos "" \
            "$USER"

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

USER $USER

ENV LISTEN_ADDRESS=0.0.0.0:8888

# Grpc port
EXPOSE 8888

COPY --from=builder /app/lspd /usr/local/bin/
COPY --from=migrate /migrate /usr/local/bin/
COPY --from=builder /app/postgresql/migrations/ /migrations/

ENTRYPOINT ["/entrypoint.sh"]