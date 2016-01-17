#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use Template::Tiny;
use Path::Class qw(file);

use inc::ZMQ2::ContextWrappers;
use inc::ZMQ2::SocketWrappers;

use inc::ZMQ3::ContextWrappers;
use inc::ZMQ3::SocketWrappers;

use inc::ZMQ4::ContextWrappers;
use inc::ZMQ4::SocketWrappers;

use inc::ZMQ4_1::ContextWrappers;
use inc::ZMQ4_1::SocketWrappers;

my %CONTEXT_WRAPPERS = (
    ZMQ2   => inc::ZMQ2::ContextWrappers->new->wrappers,
    ZMQ3   => inc::ZMQ3::ContextWrappers->new->wrappers,
    ZMQ4   => inc::ZMQ4::ContextWrappers->new->wrappers,
    ZMQ4_1 => inc::ZMQ4_1::ContextWrappers->new->wrappers,
);

my %SOCKET_WRAPPERS = (
    ZMQ2   => inc::ZMQ2::SocketWrappers->new->wrappers,
    ZMQ3   => inc::ZMQ3::SocketWrappers->new->wrappers,
    ZMQ4   => inc::ZMQ4::SocketWrappers->new->wrappers,
    ZMQ4_1 => inc::ZMQ4_1::SocketWrappers->new->wrappers,
);

for my $zmqver (sort keys %CONTEXT_WRAPPERS) {
    gen_module(
        $zmqver,
        'inc/ZmqContext.pm.tt',
        "lib/ZMQ/FFI/$zmqver/Context.pm",
        $CONTEXT_WRAPPERS{$zmqver}
    );
}

for my $zmqver (sort keys %SOCKET_WRAPPERS) {
    gen_module(
        $zmqver,
        'inc/ZmqSocket.pm.tt',
        "lib/ZMQ/FFI/$zmqver/Socket.pm",
        $SOCKET_WRAPPERS{$zmqver}
    );
}

sub gen_module {
    my ($zmqver, $template, $target, $wrappers) = @_;

    my $socket_check =
    q(if ($_[0]->socket_ptr == -1) {
        carp "Operation on closed socket";
        return;
    });

    my %tt_vars = (
        date                => split("\n", scalar(qx{date -u})),
        zmqver              => $zmqver,
        closed_socket_check => $socket_check,
        %$wrappers,
    );

    my $input = file($template)->slurp();

    # Processing twice so template tokens used in
    # zmq function wrappers also get interoplated
    my $output;
    Template::Tiny->new->process(\$input,  \%tt_vars, \$output);
    Template::Tiny->new->process(\$output, \%tt_vars, \$output);

    $target = file($target);
    say "Generating '$target'";
    $target->spew($output)
}

