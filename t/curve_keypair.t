use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Exception;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(ZMQ_REQ ZMQ_REP ZMQ_CURVE_SERVER ZMQ_CURVE_SECRETKEY 
                           ZMQ_CURVE_PUBLICKEY ZMQ_CURVE_SERVERKEY);

my $c = ZMQ::FFI->new();

my ($major, $minor) = $c->version();

my $e = "ipc://test-zmq-ffi-$$";

if ($major == 4) {
    if ($minor >= 1) {
        if ($c->has_capability("curve")) {
            my ($srv_public, $srv_secret);
            lives_ok { ($srv_public, $srv_secret) = $c->curve_keypair() }
                     'Generated curve keypair';    

            my $s1 = $c->socket(ZMQ_REP);

            $s1->set(ZMQ_CURVE_SERVER, 'int', '1');
            $s1->set(ZMQ_CURVE_SECRETKEY, 'string', $srv_secret);
        
            $s1->bind($e);
        
            my ($cli_public, $cli_secret);
            lives_ok { ($cli_public, $cli_secret) = $c->curve_keypair() }
                     'Generated curve keypair';    
        
            my $s2 = $c->socket(ZMQ_REQ);
        
            $s2->set(ZMQ_CURVE_SERVERKEY, 'string', $srv_public);
            $s2->set(ZMQ_CURVE_PUBLICKEY, 'string', $cli_public);
            $s2->set(ZMQ_CURVE_SECRETKEY, 'string', $cli_secret);
        
            $s2->connect($e);
            $s2->send("psst");
        
            is
                $s1->recv(),
                'psst',
                'received message';
            
        } else {
            # libsodium is not installed
        }
    } else {
        # zmq 4.0 (can't assume libsodium is installed)
    }
} 
else {
    throws_ok { $c->curve_keypair() }
                qr'curve_keypair not available in zmq',
                'threw unimplemented error for < 4.x';
}

done_testing;