# $USER name to be used in the `final` image
ARG USER=scheduler

FROM rust:1.78-slim-bookworm as builder

RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        protobuf-compiler

WORKDIR /app/

COPY Cargo.toml Cargo.lock ./

RUN mkdir src && \
    touch src/lib.rs && \
    cargo build --release && \
    rm -rf src

COPY . ./

RUN cargo install --path .


FROM debian:bookworm-slim as final

ARG USER

LABEL maintainer="Jesse de Wit (@JssDWt)"

RUN adduser --disabled-password \
            --home "/data" \
            --gecos "" \
            "$USER"

USER $USER

# Prevents `VOLUME /data/.scheduler/` being created as owned by `root`
RUN mkdir -p "/data/.scheduler/"

# Expose volume containing all `scheduler` data
VOLUME /data/.scheduler/

COPY --from=builder /usr/local/cargo/bin/scheduler /usr/local/bin/

ENTRYPOINT ["scheduler"]