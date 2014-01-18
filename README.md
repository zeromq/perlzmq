# ZMQ::FFI #

[![Build Status](https://travis-ci.org/calid/zmq-ffi.png?branch=master)](https://travis-ci.org/calid/zmq-ffi)

##  Perl zeromq bindings using libffi and [FFI::Raw](https://github.com/ghedo/p5-FFI-Raw) ##

ZMQ::FFI exposes a high level, transparent, OO interface to zeromq independent of the underlying libzmq version.  Where semantics differ, it will dispatch to the appropriate backend for you.  As it uses ffi, there is no dependency on XS or compilation.

### EXAMPLES ###

#### send/recv ####
```perl
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
```

#### pub/sub ####
```perl
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
```

#### multipart ####
```perl
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
```

#### nonblocking ####
```perl
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
```

#### specifying versions ####
```perl
use ZMQ::FFI;

# 2.x context
my $ctx = ZMQ::FFI->new( soname => 'libzmq.so.1' );
my ($major, $minor, $patch) = $ctx->version;

# 3.x context
my $ctx = ZMQ::FFI->new( soname => 'libzmq.so.3' );
my ($major, $minor, $patch) = $ctx->version;
```

### INSTALL ###
    # if simply wanting to use ZMQ::FFI
    cpanm ZMQ::FFI

    # if wanting to hack on the source and build the dist
    git clone git@github.com:calid/zmq-ffi.git
    cd zmq-ffi
    cpanm Dist::Zilla # if not already installed
    dzil authordeps | cpanm
    dzil build


### DOCUMENTATION ###
Full documentation can be found on [cpan](https://metacpan.org/module/ZMQ::FFI)
