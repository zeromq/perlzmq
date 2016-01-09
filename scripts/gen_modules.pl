#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use Template::Tiny;
use Path::Class qw(file);

my $tt = Template::Tiny->new();

my @socket_templates = (
    file('inc/template/lib/ZMQ/FFI/ZMQ2/Socket.pm.tt'),
    file('inc/template/lib/ZMQ/FFI/ZMQ3/Socket.pm.tt'),
    file('inc/template/lib/ZMQ/FFI/ZMQ4/Socket.pm.tt')
);

my $common_tt = file('inc/template/lib/ZMQ/FFI/Common/Socket.tt');

my $socket_check = q(if ($_[0]->socket_ptr == -1) {
        carp "Operation on closed socket";
        return;
    });

my $vars = {
    date                => split("\n", scalar(qx{date -u})),
    closed_socket_check => $socket_check,
};

for my $socket_tt (@socket_templates) {
    my $target = "$socket_tt";
    $target =~ s{^inc/template/}{}g;
    $target =~ s{\.tt$}{}g;
    $target = file($target);

    my $input = $socket_tt->slurp();
    $input   .= $common_tt->slurp();

    my $output;
    $tt->process(\$input, $vars, \$output);

    say "Generating '$target' from templates";
    $target->spew($output);
}

