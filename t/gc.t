use Test::More;
use strict;
use warnings;

use Scalar::Util qw(blessed);

use ZMQ::FFI;
use ZMQ::FFI::ContextBase;
use ZMQ::FFI::SocketBase;

use ZMQ::FFI::Constants qw(ZMQ_REQ);

my @gc_stack;

usesocket();

is_deeply
    \@gc_stack,
    ['socket', 'ctx'],
    q(socket reaped before context);

sub usesocket {
    my $s = mksocket();

    # socket should get reaped, then ctx
    return;
}

sub mksocket {
    no warnings q/redefine/;

    my $ctx = ZMQ::FFI->new();
    *ZMQ::FFI::ContextBase::DEMOLISH = sub { push @gc_stack, 'ctx' };

    my $s = $ctx->socket(ZMQ_REQ);
    *ZMQ::FFI::SocketBase::DEMOLISH = sub { push @gc_stack, 'socket' };

    # ctx should not get reaped
    return $s;
}

done_testing;
