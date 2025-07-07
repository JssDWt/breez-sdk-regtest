# $USER name to be used in the `final` image
ARG USER=lsps2

FROM rust:1.86-slim-bookworm AS builder

WORKDIR /app/

COPY Cargo.toml Cargo.lock ./

RUN mkdir src && \
    touch src/lib.rs && \
    cargo build && \
    rm -rf src

COPY src/ src/

RUN cargo install --debug --path .


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN adduser --disabled-password \
            --home "/data" \
            --gecos "" \
            "$USER"

USER $USER

COPY --from=builder /usr/local/cargo/bin/lsps2-server /usr/local/bin/

ENTRYPOINT ["lsps2-server"]
