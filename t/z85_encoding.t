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

if ($major == 4) {
    if ($minor >= 1) {
        if ($c->has_capability("curve")) {
            my ($encoded, $priv) = $c->curve_keypair;
            
            my $decoded = $c->z85_decode( $encoded );
            my $recoded = $c->z85_encode( $decoded );
            
            is
                $recoded,
                $encoded;

        } else {
            # zmq >= 4.1 - libsodium is not installed, do nothing
        }
    } else {
	# zmq == 4.0 - can't assume libsodium is installed or uninstalled
	# so we can't run the z85_encode() method
	
	# verify that has capability is not implemented before 4.1
	throws_ok { $c->has_capability() }
	            qr'has_capability not available',
                    'threw unimplemented error for < 4.1';
    }
} 
else {
    # zmq < 4.x - z85_encode / z85_decode and has capability are not implemented
    throws_ok { $c->z85_encode() }
                qr'z85_encode not available',
                'threw unimplemented error in < 4.x';   

    throws_ok { $c->z85_decode() }
                qr'z85_decode not available',
                'threw unimplemented error in < 4.x';   
                
    throws_ok { $c->has_capability() }
                qr'has_capability not available',
                'threw unimplemented error for < 4.1';
}

done_testing;
