use strict;
use warnings;

use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ);

my $ctx = ZMQ::FFI->new();
my $s   = $ctx->socket(ZMQ_REQ);

no strict qw/refs/;
no warnings qw/redefine once/;

my $fake_close = sub {
    my ($self) = @_;
    is $self->get_linger, 42, "user linger value honored during socket close";

    # need to manually set linger & close
    # since we clobbered the real method
    $self->set_linger(0);

    my $class = ref $self;
    &{"$class\::zmq_close"}($self->socket_ptr);
};

local *ZMQ::FFI::ZMQ2::Socket::close = $fake_close;
local *ZMQ::FFI::ZMQ3::Socket::close = $fake_close;

use strict;
use warnings;

is $s->get_linger, 0, "got default linger";

$s->set_linger(42);
is $s->get_linger, 42, "linger is 42 after set";

undef $s;

done_testing;
