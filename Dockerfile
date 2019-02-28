FROM ubuntu:latest as base
ENV DEBIAN_FRONTEND=noninteractive
ENV PREFIX=/root/.zmq-ffi/usr
RUN apt-get update \
    && apt-get install -y git gcc g++ make autoconf automake libtool-bin \
        pkg-config libssl-dev zlib1g-dev uuid-dev tzdata libanyevent-perl \
        locales libzmq5 \
    && locale-gen fr_FR.utf8 && update-locale \
    && apt-get clean
WORKDIR /root/.zmq-ffi
RUN git clone https://github.com/zeromq/zeromq2-x.git \
    && cd zeromq2-x \
    && ./autogen.sh \
    && ./configure --prefix=$PREFIX/zeromq2-x --disable-static \
    && make install \
    && strip --strip-unneeded $PREFIX/zeromq2-x/lib/libzmq.so \
    && git clean -dfx && git gc --aggressive --prune
RUN git clone https://github.com/zeromq/zeromq3-x.git \
    && cd zeromq3-x \
    && ./autogen.sh \
    && ./configure --prefix=$PREFIX/zeromq3-x --disable-static \
    && make install \
    && strip --strip-unneeded $PREFIX/zeromq3-x/lib/libzmq.so \
    && git clean -dfx && git gc --aggressive --prune
RUN git clone https://github.com/zeromq/zeromq4-1.git \
    && cd zeromq4-1 \
    && ./autogen.sh \
    && ./configure --prefix=$PREFIX/zeromq4-1 --disable-static \
    && make install \
    && strip --strip-unneeded $PREFIX/zeromq4-1/lib/libzmq.so \
    && git clean -dfx && git gc --aggressive --prune
RUN git clone https://github.com/zeromq/zeromq4-x.git \
    && cd zeromq4-x \
    && ./autogen.sh \
    && ./configure --prefix=$PREFIX/zeromq4-x --disable-static \
    && make install \
    && strip --strip-unneeded $PREFIX/zeromq4-x/lib/libzmq.so \
    && git clean -dfx && git gc --aggressive --prune
RUN git clone https://github.com/zeromq/libzmq.git \
    && cd libzmq \
    && ./autogen.sh \
    && ./configure --prefix=$PREFIX/libzmq --disable-static \
    && make install \
    && strip --strip-unneeded $PREFIX/libzmq/lib/libzmq.so \
    && git clean -dfx && git gc --aggressive --prune

FROM base as zmq-base
COPY scripts/print_zmq_msg_size.c zmq_msg_size/
RUN cd zmq_msg_size \
    && \
    gcc -I$PREFIX/zeromq2-x/include print_zmq_msg_size.c \
        -o print_zeromq2-x_msg_size \
        -Wl,-rpath=$PREFIX/zeromq2-x/lib -L$PREFIX/zeromq2-x/lib -lzmq \
    && ./print_zeromq2-x_msg_size >> zmq_msg_sizes \
    && \
    gcc -I$PREFIX/zeromq3-x/include print_zmq_msg_size.c \
        -o print_zeromq3-x_msg_size \
        -Wl,-rpath=$PREFIX/zeromq3-x/lib -L$PREFIX/zeromq3-x/lib -lzmq \
    && ./print_zeromq3-x_msg_size >> zmq_msg_sizes \
    && \
    gcc -I$PREFIX/zeromq4-1/include print_zmq_msg_size.c \
        -o print_zeromq4-1_msg_size \
        -Wl,-rpath=$PREFIX/zeromq4-1/lib -L$PREFIX/zeromq4-1/lib -lzmq \
    && ./print_zeromq4-1_msg_size >> zmq_msg_sizes \
    && \
    gcc -I$PREFIX/zeromq4-x/include print_zmq_msg_size.c \
        -o print_zeromq4-x_msg_size \
        -Wl,-rpath=$PREFIX/zeromq4-x/lib -L$PREFIX/zeromq4-x/lib -lzmq \
    && ./print_zeromq4-x_msg_size >> zmq_msg_sizes \
    && \
    gcc -I$PREFIX/libzmq/include print_zmq_msg_size.c \
        -o print_libzmq_msg_size \
        -Wl,-rpath=$PREFIX/libzmq/lib -L$PREFIX/libzmq/lib -lzmq \
    && ./print_libzmq_msg_size >> zmq_msg_sizes

FROM zmq-base as dzil-base
RUN apt-get install -y cpanminus && apt-get clean \
    && cpanm -v Dist::Zilla

FROM dzil-base as zmq-ffi-base
COPY . /zmq-ffi/
RUN cd /zmq-ffi && dzil authordeps --missing | cpanm -v
RUN cd /zmq-ffi && dzil listdeps --missing | cpanm -v
RUN apt-get -y purge gcc g++ autoconf automake libtool-bin pkg-config \
    libssl-dev zlib1g-dev uuid-dev \
    && apt -y autoremove \
    && rm -r /var/lib/apt/lists/* ~/.cpanm /zmq-ffi /usr/local/share/man/* \
             /usr/share/doc/*

FROM scratch
COPY --from=zmq-ffi-base / /
