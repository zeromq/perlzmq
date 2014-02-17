package ZMQ::FFI;
# ABSTRACT: zeromq bindings using libffi and FFI::Raw

use ZMQ::FFI::Util qw(zmq_soname zmq_version);
use ZMQ::FFI::ErrorHelper;
use Carp;

sub new {
    my $self = shift;
    my %args = @_;

    $args{soname} //= zmq_soname( die => 1 );

    # explicitly passing in a loaded error helper instance
    # (i.e. zmq error bindings) guards against the OS X loader clobbering errno,
    # which can happen if the bindings are loaded lazily
    $args{error_helper} =
        ZMQ::FFI::ErrorHelper->new( soname => $args{soname} );

    my ($major) = zmq_version($args{soname});

    if ($major == 2) {
        require ZMQ::FFI::ZMQ2::Context;
        return ZMQ::FFI::ZMQ2::Context->new(%args);
    }
    else {
        require ZMQ::FFI::ZMQ3::Context;
        return ZMQ::FFI::ZMQ3::Context->new(%args);
    }
};

1;

__END__

=head1 SYNOPSIS

    #### send/recv ####

    use v5.10;
    use ZMQ::FFI;
    use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_REP);

    my $endpoint = "ipc://zmq-ffi-$$";
    my $ctx      = ZMQ::FFI->new( threads => 1 );

    my $s1 = $ctx->socket(ZMQ_REQ);
    $s1->connect($endpoint);

    my $s2 = $ctx->socket(ZMQ_REP);
    $s2->bind($endpoint);

    $s1->send('ohhai');

    say $s2->recv();
    # ohhai


    #### pub/sub ####

    use v5.10;
    use ZMQ::FFI;
    use ZMQ::FFI::Constants qw(ZMQ_PUB ZMQ_SUB);
    use Time::HiRes q(usleep);

    my $endpoint = "ipc://zmq-ffi-$$";
    my $ctx      = ZMQ::FFI->new();

    my $s = $ctx->socket(ZMQ_SUB);
    my $p = $ctx->socket(ZMQ_PUB);

    $s->connect($endpoint);
    $p->bind($endpoint);

    # all topics
    {
        $s->subscribe('');
        $p->send('ohhai');

        until ($s->has_pollin) {
            # compensate for slow subscriber
            usleep 100_000;
            $p->send('ohhai');
        }

        say $s->recv();
        # ohhai

        $s->unsubscribe('');
    }

    # specific topics
    {
        $s->subscribe('topic1');
        $s->subscribe('topic2');

        $p->send('topic1 ohhai');
        $p->send('topic2 ohhai');

        until ($s->has_pollin) {
            usleep 100_000;
            $p->send('topic1 ohhai');
            $p->send('topic2 ohhai');
        }

        while ($s->has_pollin) {
            say join ' ', $s->recv();
            # topic1 ohhai
            # topic2 ohhai
        }
    }


    #### multipart ####

    use v5.10;
    use ZMQ::FFI;
    use ZMQ::FFI::Constants qw(ZMQ_DEALER ZMQ_ROUTER);

    my $endpoint = "ipc://zmq-ffi-$$";
    my $ctx      = ZMQ::FFI->new();

    my $d = $ctx->socket(ZMQ_DEALER);
    $d->set_identity('dealer');

    my $r = $ctx->socket(ZMQ_ROUTER);

    $d->connect($endpoint);
    $r->bind($endpoint);

    $d->send_multipart([qw(ABC DEF GHI)]);

    say join ' ', $r->recv_multipart;
    # dealer ABC DEF GHI


    #### nonblocking ####

    use v5.10;
    use ZMQ::FFI;
    use ZMQ::FFI::Constants qw(ZMQ_PUSH ZMQ_PULL);
    use AnyEvent;
    use EV;

    my $endpoint = "ipc://zmq-ffi-$$";
    my $ctx      = ZMQ::FFI->new();
    my @messages = qw(foo bar baz);


    my $pull = $ctx->socket(ZMQ_PULL);
    $pull->bind($endpoint);

    my $fd = $pull->get_fd();

    my $recv = 0;
    my $w = AE::io $fd, 0, sub {
        while ( $pull->has_pollin ) {
            say $pull->recv();
            # foo, bar, baz

            $recv++;
            if ($recv == 3) {
                EV::unloop();
            }
        }
    };


    my $push = $ctx->socket(ZMQ_PUSH);
    $push->connect($endpoint);

    my $sent = 0;
    my $t;
    $t = AE::timer 0, .1, sub {
        $push->send($messages[$sent]);

        $sent++;
        if ($sent == 3) {
            undef $t;
        }
    };

    EV::run();


    #### specifying versions ####

    use ZMQ::FFI;

    # 2.x context
    my $ctx = ZMQ::FFI->new( soname => 'libzmq.so.1' );
    my ($major, $minor, $patch) = $ctx->version;

    # 3.x context
    my $ctx = ZMQ::FFI->new( soname => 'libzmq.so.3' );
    my ($major, $minor, $patch) = $ctx->version;


=head1 DESCRIPTION

ZMQ::FFI exposes a high level, transparent, OO interface to zeromq independent
of the underlying libzmq version.  Where semantics differ, it will dispatch to
the appropriate backend for you.  As it uses ffi, there is no dependency on XS
or compilation.

=head1 CONTEXT API

=head2 new([threads, max_sockets, soname])

    ZMQ::FFI->new( threads => 42, max_sockets => 42 )

returns a new context object, appropriate for the version of
libzmq found on your system. It accepts the following optional attributes:

=over 4

=item threads

zeromq thread pool size. Default: 1

=item max_sockets

I<only for zeromq 3.x>

max number of sockets allowed for context. Default: 1024

=item soname

specify the libzmq library name to load.  By default ZMQ::FFI will try the
linker name, C<libzmq.so>, and then the sonames C<libzmq.so.3> and
C<libzmq.so.1>, in that order. C<soname> can also be the path to a particular
libzmq so file

It is technically possible to have multiple contexts of different versions in
the same process, though the utility of doing such a thing is dubious

=back

=head2 ($major, $minor, $patch) = version()

return the libzmq version as the list C<($major, $minor, $patch)>

=head2 get($option)

I<only for zeromq 3.x>

    $ctx->get(ZMQ_IO_THREADS)

get a context option value

=head2 set($option, $option_value)

I<only for zeromq 3.x>

    $ctx->set(ZMQ_MAX_SOCKETS, 42)

set a context option value

=head2 socket($type)

    $ctx->socket(ZMQ_REQ)

returns a socket of the specified type. See L<SOCKET API> below

=head2 destroy()

destroys the underlying zmq context. This is called automatically when the
object gets reaped

=head1 SOCKET API

The following API is available on socket objects created by C<$ctx-E<gt>socket>.

For core attributes and functions, common across all versions of zeromq,
convenience methods are provided. Otherwise, generic get/set methods are
provided that will work independent of version.

As attributes are constantly being added/removed from zeromq, it is unlikely the
'static' accessors will grow much beyond the current set.

=head2 ($major, $minor, $patch) = version()

same as Context version() above

=head2 connect($endpoint)

does socket connect on the specified endpoint

=head2 bind($endpoint)

does socket bind on the specified endpoint

=head2 get_linger(), set_linger($millis)

get or set the current socket linger period

=head2 get_identity(), set_identity($ident)

get or set the socket identity for request/reply patterns

=head2 get_fd()

get the file descriptor associated with the socket

=head2 subscribe($topic)

add C<$topic> to the subscription list

=head2 unsubscribe($topic)

remove C<$topic> from the subscription list

=head2 send($msg, [$flags])

    $socket->send('ohhai')

sends a message using the optional flags

=head2 send_multipart($parts_aref, [$flags])

    $socket->send([qw(foo bar baz)])

given an array ref of message parts, sends the multipart message using the
optional flags. ZMQ_SNDMORE semantics are handled for you

=head2 recv([$flags])

receive a message

=head2 @parts = recv_multipart([$flags])

receives a multipart message, returning an array of parts. ZMQ_RCVMORE
semantics are handled for you

=head2 has_pollin, has_pollout

checks ZMQ_EVENTS for ZMQ_POLLIN and ZMQ_POLLOUT respectively, and returns
true/false depending on the state

=head2 get($option, $option_type)

    $socket->get(ZMQ_LINGER, 'int')

return the value for the specified socket option. C<$option_type> is the type
associated with the option value in the zeromq API (C<zmq_getsockopt> man page)

=head2 set($option, $option_type, $option_value)

    $socket->set(ZMQ_IDENTITY, 'binary', 'foo')

set the socket option to the specified value. C<$option_type> is the type
associated with the option value in the zeromq API (C<zmq_setsockopt> man page)

=head2 close()

close the underlying zmq socket. This is called automatically when the object
gets reaped

=head1 ERROR HANDLING

ZMQ::FFI checks the return codes of underlying zmq functions for you, and in the
case of an error it will die with the plain english system error message.

    $ctx->socket(-1);
    # dies with 'zmq_socket: Invalid argument'

=head1 SEE ALSO

=for :list
* L<ZMQ::FFI::Constants>
* L<ZMQ::FFI::Util>
* L<FFI::Raw>

