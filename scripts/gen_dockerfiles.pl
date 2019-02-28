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
COPY --from=builder /usr/local/[% zmq %] [% zmq %]/
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

# create convenience image with all zmqs and alpine base, generate zmq_msg_t
# sizes (replaces TinyCC)
my $zmq_all_docker_tt = <<'END';
FROM calid/alpine-base:latest

COPY scripts/print_zmq_msg_size.c .
[% FOREACH zmq IN zmqs %]
COPY --from=calid/[% zmq %]:alpine [% zmq %] [% zmq %]/
RUN cc -I/[% zmq %]/include print_zmq_msg_size.c \
   -o print_[% zmq %]_msg_size -Wl,-rpath=/[% zmq %]/lib -L/[% zmq %]/lib -lzmq
RUN ./print_[% zmq %]_msg_size >> zmq_msg_sizes
[% END %]
END

my $output;
my %tt_vars = (
    zmqs => \@zmqs
);

Template::Tiny->new->process(\$zmq_all_docker_tt, \%tt_vars, \$output);

my $target = file('docker/Dockerfile.zmq-all');
$target->spew($output);

# finally generate zmq-ffi testing environment dockerfile
my $zmq_ffi_test_base_docker_tt = <<'END';
FROM calid/zmq-all:alpine as perl-base
RUN apk --no-cache add wget openssl-dev tzdata zlib-dev musl-dev zeromq-dev \
                       perl-dev perl-net-ssleay perl-app-cpanminus

FROM perl-base
RUN cpanm -v Dist::Zilla
END

%tt_vars = (
    zmqs => \@zmqs
);

Template::Tiny->new->process(
    \$zmq_ffi_test_base_docker_tt, \%tt_vars, \$output
);

$target = file('docker/Dockerfile.zmq-ffi-test-base');
$target->spew($output);

my $zmq_ffi_testenv_docker = file('docker/Dockerfile.zmq-ffi-testenv');
$zmq_ffi_testenv_docker->spew(q(
FROM calid/zmq-ffi-test-base:alpine
COPY . /zmq-ffi
WORKDIR /zmq-ffi
RUN dzil authordeps --missing | cpanm -v
# RUN dzil listdeps --missing | cpanm -v
# WORKDIR /
# RUN rm -rf ~/.cpanm /zmq-ffi
));

