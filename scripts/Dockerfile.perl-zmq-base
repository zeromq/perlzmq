FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y gcc make libzmq5 openssl libssl-dev zlib1g-dev \
        cpanminus \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/local/share/man/* /usr/share/doc/*
