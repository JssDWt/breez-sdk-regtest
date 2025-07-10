# $USER name to be used in the `final` image
ARG USER=lsps2

FROM rust:1.86-slim-bookworm AS builder

WORKDIR /app/

COPY Cargo.toml Cargo.lock ./

RUN mkdir src && \
    touch src/lib.rs && \
    cargo build --release && \
    rm -rf src

COPY src/ src/

RUN cargo install --path .


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password \
            --home "/data" \
            --gecos "" \
            "$USER"

USER $USER

COPY entrypoint.sh /
COPY --from=builder /usr/local/cargo/bin/lsps2-server /usr/local/bin/

ENTRYPOINT ["/entrypoint.sh"]
