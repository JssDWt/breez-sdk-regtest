# $USER name to be used in the `final` image
ARG USER=cln
ARG VERSION=162b0322cbf916971dc6d77605c9f20f0ba91559
ARG REPOSITORY=https://github.com/breez/lspd.git

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

RUN make release-plugin


FROM lightningd AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

USER root

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        curl \
        jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

USER $USER

# lightningd grpc port
EXPOSE 8888

# cln_plugin grpc port
EXPOSE 12312

COPY --from=builder /app/lspd_cln_plugin /usr/local/bin/

ENTRYPOINT ["/entrypoint.sh"]

CMD [ \
    "--lightning-dir='/data/.lightning'" \
    "--grpc-port=8888", \
    "--plugin=lspd_cln_plugin", \
    "--lsp-listen=0.0.0.0:12312", \
    "--developer", \
    "--dev-allowdustreserve=true" \
]