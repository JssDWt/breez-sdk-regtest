# $USER name to be used in the `final` image
ARG USER=cln
ARG VERSION=c951e86945dee7613467e9977843f3ed6a23e76b
ARG REPOSITORY=https://github.com/breez/lspd.git

FROM debian:bookworm-slim as downloader

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


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN adduser --disabled-password \
            --home "/data/" \
            --gecos "" \
            "$USER"

USER $USER

ENV LISTEN_ADDRESS=0.0.0.0:8888

# Grpc port
EXPOSE 8888

COPY --from=builder /app/lspd /usr/local/bin/

ENTRYPOINT ["lspd"]