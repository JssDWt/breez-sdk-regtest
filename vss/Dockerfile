FROM rust:1.70

WORKDIR /usr/src/app

RUN git clone https://github.com/lightningdevkit/vss-server .
RUN cargo install --path rust/server

ENTRYPOINT ["server"]
