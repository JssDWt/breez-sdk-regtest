# $USER name to be used in the `final` image
ARG USER=server
ARG VERSION=a7202886f782cc8305af1fb4747568e39cfb68dd
ARG REPOSITORY=https://github.com/breez/server.git

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

RUN COMMIT=$(git rev-parse HEAD) \
    CGO_ENABLED=0 \
    go build -trimpath -ldflags "-X main.commit=${COMMIT}" .


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN adduser --disabled-password \
            --home "/data" \
            --gecos "" \
            "$USER"

USER $USER

# Grpc port
EXPOSE 8080

# Grpc port
EXPOSE 9999

COPY --from=builder /app/server /usr/local/bin/

ENTRYPOINT ["server"]