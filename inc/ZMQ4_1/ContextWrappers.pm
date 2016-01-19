package inc::ZMQ4_1::ContextWrappers;

use Moo;
use namespace::clean;

extends 'inc::ZMQ4::ContextWrappers';

sub has_capability_tt {q(
sub has_capability {
    my ($self, $capability) = @_;
    return zmq_has($capability);
}
)}

1;
