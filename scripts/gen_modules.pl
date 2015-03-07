#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use Template::Tiny;
use Path::Class qw(file);

my $tt = Template::Tiny->new();

my @templates = (
    file('inc/template/lib/ZMQ/FFI/ZMQ2/Socket.pm.tt'),
    file('inc/template/lib/ZMQ/FFI/ZMQ3/Socket.pm.tt')
);

my $common_ffi = file('inc/template/lib/ZMQ/FFI/Common/Socket.in');

my $vars = {
    date           => split("\n", scalar(qx{date -u})),
    zmq_common_api => scalar $common_ffi->slurp()
};

for my $template (@templates) {
    my $target = "$template";
    $target =~ s{^inc/template/}{}g;
    $target =~ s{\.tt$}{}g;
    $target = file($target);

    my $input = $template->slurp();
    my $output;

    $tt->process(\$input, $vars, \$output);

    say "Generating '$target'\n\tfrom '$template'\n\tusing $common_ffi";
    $target->spew($output);
}

