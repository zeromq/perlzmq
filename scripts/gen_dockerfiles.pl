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
RUN apk --no-cache add ca-certificates
RUN apk --no-cache add git gcc g++ tar file libuuid make autoconf automake \
                       libtool pkgconfig util-linux-dev
));

# now generate zmq specific dockerfiles
my $zmq_docker_tt = <<'END';
FROM calid/alpine-base:latest as builder
RUN git clone https://github.com/zeromq/[% zmq %].git
WORKDIR [% zmq %]
RUN ./autogen.sh && ./configure --disable-static --prefix=/usr/local/[% zmq %] \
    && make install && strip --strip-unneeded /usr/local/[% zmq %]/lib/libzmq.so

FROM scratch
COPY --from=builder /usr/local/[% zmq %]/lib/libzmq.so [% zmq %]/
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
my $zmq_ffi_test_docker_tt = <<'END';
FROM calid/alpine-base:latest as perl-base
RUN apk --no-cache add wget openssl-dev tzdata zlib-dev musl-dev zeromq-dev \
                       perl-dev perl-net-ssleay perl-app-cpanminus

FROM perl-base as dzil-base
RUN cpanm -v Dist::Zilla

FROM dzil-base as zmq-ffi-base
RUN git clone https://github.com/calid/zmq-ffi.git
WORKDIR zmq-ffi
RUN dzil authordeps --missing | cpanm -v \
    && dzil listdeps --missing | cpanm -v
WORKDIR /
RUN rm -rf ~/.cpanm zmq-ffi

FROM zmq-ffi-base
[% FOREACH zmq IN zmqs %]
COPY --from=calid/[% zmq %]:alpine [% zmq %]/libzmq.so [% zmq %]/libzmq.so
[% END %]
END

my $output;
my %tt_vars = (
    zmqs => \@zmqs
);

Template::Tiny->new->process(\$zmq_ffi_test_docker_tt, \%tt_vars, \$output);

my $target = file('docker/Dockerfile.zmq-ffi');
$target->spew($output);
