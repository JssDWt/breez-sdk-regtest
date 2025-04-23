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


ENTRYPOINT ["/entrypoint.sh"]

CMD [ \
    "--lightning-dir='/data/.lightning'", \
    "--grpc-port=8888" \
]