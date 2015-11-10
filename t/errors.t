use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Exception;

use FFI::Platypus;
use Errno qw(EINVAL EAGAIN);

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(:all);
use ZMQ::FFI::Util qw(zmq_soname);

subtest 'socket errors' => sub {
    $! = EINVAL;
    my $einval_str;

    {
        # get the EINVAL error string in a locale aware way
        use locale;
        use bytes;
        $einval_str = "$!";
    }

    my $ctx = ZMQ::FFI->new();

    throws_ok { $ctx->socket(-1) } qr/$einval_str/i,
        q(invalid socket type dies with EINVAL);


    my $socket = $ctx->socket(ZMQ_REQ);

    throws_ok { $socket->connect('foo') } qr/$einval_str/i,
        q(invalid endpoint dies with EINVAL);
};

subtest 'util errors' => sub {
    no warnings q/redefine/;

    local *FFI::Platypus::function = sub { return; };

    throws_ok { zmq_soname(die => 1) } qr/Could not load libzmq/,
        q(zmq_soname dies when die => 1 and FFI::Platypus->function fails);

    lives_ok {
        ok !zmq_soname();
    } q(zmq_soname lives and returns undef when die => 0)
    . q( and FFI::Platypus->function fails);
};

subtest 'fatal socket error' => sub {
    no warnings qw/redefine once/;

    local *ZMQ::FFI::ZMQ2::Socket::zmq_send = sub { return -1; };
    local *ZMQ::FFI::ZMQ3::Socket::zmq_send = sub { return -1; };

    my $ctx = ZMQ::FFI->new();
    my $socket = $ctx->socket(ZMQ_REQ);

    throws_ok { $socket->send('ohhai'); } qr/^zmq_send:/,
        q(socket error on send dies with zmq_send error message);
};

subtest 'socket recv error && die_on_error => false' => sub {
    my $ctx    = ZMQ::FFI->new();
    my $socket = $ctx->socket(ZMQ_REP);
    $socket->bind("ipc://test-zmq-ffi-$$");

    check_nonfatal_eagain($socket, 'recv', ZMQ_DONTWAIT);
};

subtest 'socket send error && die_on_error => false' => sub {
    my $ctx    = ZMQ::FFI->new();
    my $socket = $ctx->socket(ZMQ_DEALER);
    $socket->bind("ipc://test-zmq-ffi-$$");

    check_nonfatal_eagain($socket, 'send', 'ohhai', ZMQ_DONTWAIT);
};

subtest 'socket recv_multipart error && die_on_error => false' => sub {
    my $ctx    = ZMQ::FFI->new();
    my $socket = $ctx->socket(ZMQ_REP);
    $socket->bind("ipc://test-zmq-ffi-$$");

    check_nonfatal_eagain($socket, 'recv_multipart', ZMQ_DONTWAIT);
};

subtest 'socket send_multipart error && die_on_error => false' => sub {
    my $ctx    = ZMQ::FFI->new();
    my $socket = $ctx->socket(ZMQ_DEALER);
    $socket->bind("ipc://test-zmq-ffi-$$");

    check_nonfatal_eagain(
        $socket, 'send_multipart', [qw(foo bar baz)], ZMQ_DONTWAIT
    );
};

sub check_nonfatal_eagain {
    my ($socket, $method, @method_args) = @_;

    $! = EAGAIN;
    my $eagain_str;

    {
        # get the EAGAIN error string in a locale aware way
        use locale;
        use bytes;
        $eagain_str = "$!";
    }

    $socket->die_on_error(0);

    ok !$socket->has_error,
        qq(has_error false before $method error);

    lives_ok {
        $socket->$method(@method_args);
    } qq($method error isn't fatal if die_on_error false);

    ok $socket->has_error,
        'has_error true after error';

    is $socket->last_errno, EAGAIN,
        'last_errno set to error code of last error';

    is $socket->last_strerror, $eagain_str,
        'last_strerror set to error string of last error';

    $socket->die_on_error(1);

    throws_ok { $socket->$method(@method_args) } qr/$eagain_str/i,
        qq($method error fatal again after die_on_error set back to true);
}

done_testing;
