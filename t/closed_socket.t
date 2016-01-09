use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Warnings qw(warnings);

use ZMQ::FFI qw(ZMQ_REQ);
use ZMQ::FFI::SocketRole;

my @socket_methods = ZMQ::FFI::SocketRole->meta->get_required_method_list();

my @expected_warnings;
push @expected_warnings, re('Operation on closed socket')
    for (@socket_methods);

sub f {
    my $c = ZMQ::FFI->new();
    return $c->socket(ZMQ_REQ);
}

my @actual_warnings = warnings {
    my $s = f();

    for my $method (@socket_methods) {
        $s->$method()
    }
};

cmp_deeply(
    \@actual_warnings,
    \@expected_warnings,
    'got warnings for operations on closed socket'
);

done_testing;
