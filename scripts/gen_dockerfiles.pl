#!/usr/bin/env perl

use feature 'say';
use strict;
use warnings;

use Template::Tiny;
use Path::Class qw(file dir);

dir('docker')->mkpath();

# first generate our alpine base dockerfile
my $alpine_base_docker = file('docker/Dockerfile.alpine-base');
$alpine_base_docker->spew(q(
FROM alpine:latest
RUN apk --no-cache add ca-certificates && apk update
RUN apk add git gcc g++ tar file libuuid make autoconf automake libtool \
            pkgconfig util-linux-dev
));

# now generate zmq specific dockerfiles
my $zmq_docker_tt = <<'END';
FROM calid/alpine-base:latest as builder
RUN git clone https://github.com/zeromq/[% zmq %].git
WORKDIR [% zmq %]
RUN ./autogen.sh && ./configure --disable-static --prefix=/usr/local/[% zmq %] \
    && make install
WORKDIR /
RUN rm -rf [% zmq %]

FROM scratch
COPY --from=builder /usr/local/[% zmq %] .
END

my @zmqs = qw(zeromq2-x zeromq3-x zeromq4-x zeromq4-1 libzmq);

for my $z (@zmqs) {
    my %tt_vars = (
        zmq => $z
    );

    my $output;
    Template::Tiny->new->process(\$zmq_docker_tt, \%tt_vars, \$output);

    my $target = file("docker/Dockerfile.$z");
    $target->spew($output);
}

# finally generate zmq-ffi testing environment dockerfile
my $zmq_ffi_test_docker = file('docker/Dockerfile.zmq-ffi');
$zmq_ffi_test_docker->spew(qw(
FROM alpine-base:latest
RUN apk add wget openssl-dev zlib-dev musl-dev \
        perl-dev perl-net-ssleay perl-app-cpanminus \
    && cpanm -v Dist::Zilla
));
