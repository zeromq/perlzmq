use strict;
use warnings;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ);

my $context = ZMQ::FFI->new();
my $socket = $context->socket(ZMQ_REQ);

sub closure { $socket }

# Suprisingly, the above can cause this script to hang.  Closing over $socket
# may result in $context getting cleaned up before $socket during global
# destruction.  This is despite the fact that $socket has a reference to
# $context, and therefore would be expected to get cleaned up first (and
# always does during normal destruction).
#
# This triggers a hang as zmq contexts block during cleanup until close has
# been called on all sockets. So for single threaded applications you _must_
# close all sockets before attempting to destroy the context.
#
# Remove the closure and global destruction cleanup happens in the expected
# order. However the lesson of course is to not assume _any_ particular
# cleanup order during GD. The ordering may change with different perl
# versions, different arrangements of the code, different directions of the
# wind, etc.
#
# The old adage "all bets are off during global destruction" is still true
# and code that assumes a particular cleanup order during GD will fail
# eventually.
