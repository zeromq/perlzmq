use strict;
use warnings;

use Test::More;
use Test::Exception;

use ZMQ::FFI;
use ZMQ::FFI::Util qw(zmq_soname zmq_version);
use ZMQ::FFI::Constants qw(:all);

subtest 'util zmq_version different sonames',
sub {

    ok
        join('.', zmq_version('libzmq.so.1'))
        =~ m/^2(\.\d+){2}$/,
        'libzmq.so.1 soname gives 2.x version';

    ok
        join('.', zmq_version('libzmq.so.3'))
        =~ m/^3(\.\d+){2}$/,
        'libzmq.so.3 soname gives 3.x version';

    throws_ok { zmq_version('libzmq.so.X') }
        qr/libzmq.so.X: cannot open shared object file/,
        'bad soname throws error';

};

subtest 'parallel version contexts',
sub
{

    my $ctx_v2 = ZMQ::FFI->new(soname => 'libzmq.so.1');
    my $ctx_v3 = ZMQ::FFI->new(soname => 'libzmq.so.3');

    ok
        join('.', $ctx_v2->version)
        =~ m/^2(\.\d+){2}$/,
        'libzmq.so.1 soname gives 2.x version';

    ok
        join('.', $ctx_v3->version)
        =~ m/^3(\.\d+){2}$/,
        'libzmq.so.3 soname gives 3.x version';

    throws_ok { ZMQ::FFI->new(soname => 'libzmq.so.X') }
        qr/libzmq\.so\.X: cannot open shared object file/,
        'bad soname throws error';


    my $v2_endpoint = "ipc:///tmp/zmq-ffi-ctx2-$$";
    my $v3_endpoint = "ipc:///tmp/zmq-ffi-ctx3-$$";

    my $s_v2_req = $ctx_v2->socket(ZMQ_REQ);
    $s_v2_req->connect($v2_endpoint);

    my $s_v3_req = $ctx_v3->socket(ZMQ_REQ);
    $s_v3_req->connect($v3_endpoint);

    my $s_v2_rep = $ctx_v2->socket(ZMQ_REP);
    $s_v2_rep->bind($v2_endpoint);

    my $s_v3_rep = $ctx_v3->socket(ZMQ_REP);
    $s_v3_rep->bind($v3_endpoint);

    $s_v2_req->send(join('.', $ctx_v2->version), ZMQ_NOBLOCK);
    $s_v3_req->send(join('.', $ctx_v3->version), ZMQ_DONTWAIT);

    ok
        $s_v2_rep->recv()
        =~ m/^2(\.\d+){2}$/,
        'got zmq 2.x message';

    ok
        $s_v3_rep->recv()
        =~ m/^3(\.\d+){2}$/,
        'got zmq 3.x message';
};

done_testing;

