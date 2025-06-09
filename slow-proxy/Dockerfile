FROM debian:bookworm-slim AS final

LABEL maintainer="Jesse de Wit (@JssDWt)"

# Install tc to simulate a slow, unreliable network.
RUN apt-get update  && \
    apt-get install -qq -y --no-install-recommends \
        iproute2 socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY simulate-*.sh /bin/

# Simulate a slow, unreliable network with /bin/simulate-*.sh scripts.
# Proxy with socat: socat TCP-LISTEN:3080,reuseaddr,fork TCP:vss-server:3080
