use Test::More;
use strict;
use warnings;

use ZMQ::FFI;
use ZMQ::FFI::ZMQ2::Context;
use ZMQ::FFI::ZMQ2::Socket;
use ZMQ::FFI::ZMQ3::Context;
use ZMQ::FFI::ZMQ3::Socket;

use ZMQ::FFI::Constants qw(ZMQ_REQ);
use ZMQ::FFI::Util qw(zmq_version);

my @gc_stack;

my ($major) = zmq_version;
if ($major == 2) {
    no warnings q/redefine/;

    local *ZMQ::FFI::ZMQ2::Context::DEMOLISH = sub {
        push @gc_stack, 'ctx'
    };

    local *ZMQ::FFI::ZMQ2::Socket::DEMOLISH = sub {
        push @gc_stack, 'socket'
    };

    use warnings;

    usesocket();

    is_deeply
        \@gc_stack,
        ['socket', 'ctx'],
        q(socket reaped before context);
}
else {
    no warnings q/redefine/;

    local *ZMQ::FFI::ZMQ3::Context::DEMOLISH = sub {
        push @gc_stack, 'ctx'
    };

    local *ZMQ::FFI::ZMQ3::Socket::DEMOLISH  = sub {
        push @gc_stack, 'socket'
    };

    use warnings;

    usesocket();

    is_deeply
        \@gc_stack,
        ['socket', 'ctx'],
        q(socket reaped before context);
}

sub usesocket {
    my $s = mksocket();

    # socket should get reaped, then ctx
    return;
}

sub mksocket {
    my $ctx = ZMQ::FFI->new();
    my $s = $ctx->socket(ZMQ_REQ);

    # ctx should not get reaped
    return $s;
}

done_testing;
