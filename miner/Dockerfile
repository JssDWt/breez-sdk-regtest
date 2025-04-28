# $USER name to be used in the `final` image
ARG USER=miner

FROM rust:1.86-slim-bookworm AS builder

# RUN apt-get update -qq && \
#     apt-get install -qq -y --no-install-recommends \
#         build-essential \
#         ca-certificates \
#         git \
#         protobuf-compiler

WORKDIR /app/

COPY Cargo.toml Cargo.lock ./

RUN mkdir src && \
    touch src/lib.rs && \
    cargo build --release && \
    rm -rf src

COPY . ./

RUN cargo install --path .


FROM debian:bookworm-slim AS final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN adduser --disabled-password \
            --home "/data" \
            --gecos "" \
            "$USER"

USER $USER

COPY --from=builder /usr/local/cargo/bin/miner /usr/local/bin/

ENTRYPOINT ["miner"]