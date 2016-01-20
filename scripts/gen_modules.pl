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

my @wrappers;

for my $zmqver (qw(ZMQ2 ZMQ3 ZMQ4 ZMQ4_1)) {
    my $context_wrapper = "inc::${zmqver}::ContextWrappers";
    my $socket_wrapper  = "inc::${zmqver}::SocketWrappers";

    push @wrappers, $context_wrapper->new( zmqver => $zmqver );
    push @wrappers, $socket_wrapper->new( zmqver => $zmqver );
}

gen_module($_) for @wrappers;

sub gen_module {
    my ($wrapper) = @_;

    my $socket_check =
    q(if ($_[0]->socket_ptr == -1) {
        carp "Operation on closed socket";
        return;
    });

    my $api_wrappers = $wrapper->wrappers;

    my %tt_vars = (
        date                => split("\n", scalar(qx{date -u})),
        zmqver              => $wrapper->zmqver,
        closed_socket_check => $socket_check,
        api_methods         => $wrapper->api_methods,
        lib_imports         => $wrapper->lib_imports,
        %$api_wrappers,
    );

    my $input = $wrapper->template->slurp();

    # Processing twice so template tokens used in
    # zmq function wrappers also get interoplated
    my $output;
    Template::Tiny->new->process(\$input,  \%tt_vars, \$output);
    Template::Tiny->new->process(\$output, \%tt_vars, \$output);

    my $target = $wrapper->target;
    say "Generating '$target'";
    $target->spew($output)
}

