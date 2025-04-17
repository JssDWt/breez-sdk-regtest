FROM rust:1.70

WORKDIR /usr/src/app

RUN git clone https://github.com/lightningdevkit/rapid-gossip-sync-server.git .
RUN cargo install --path .

WORKDIR /usr/src/app
