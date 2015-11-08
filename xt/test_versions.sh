#!/bin/bash

set -e

function zmq_version {
    echo $(\
        PERL5LIB=lib:$PERL5LIB \
        perl -M'ZMQ::FFI::Util q(zmq_version)' \
        -E 'print join " ",zmq_version'\
    )
}

function buildzmq {
    version="$1"
    tmpdir=`mktemp -d`
    if [[ "$version" == "libzmq" ]]; then
        git clone "https://github.com/zeromq/libzmq.git" $tmpdir
    else
        git clone "https://github.com/zeromq/zeromq${version}.git" $tmpdir
    fi
    ( cd $tmpdir
        ./autogen.sh
        ./configure --without-libsodium
        make -j2 )
    export LD_LIBRARY_PATH=$tmpdir/src/.libs
}

function local_test {
    test_version=$1

    if [[ "$test_version" == "libzmq" ]]; then
        export LD_LIBRARY_PATH="$HOME/git/libzmq/src/.libs"
    else
        export LD_LIBRARY_PATH="$HOME/git/zeromq$test_version/src/.libs"
    fi

    echo -e "\nTesting zeromq" \
        "$(zmq_version | tr ' ' '.')"

    run_prove

    # extra test to check that out-of-order cleanup during global destruction
    # is handled and doesn't cause a program hang
    PERL5LIB=lib:$PERL5LIB timeout 1 perl xt/gc_global_destruction.pl \
        || (\
            echo "xt/gc_global_destruction.pl timed out during cleanup" >&2 \
            && exit 1 \
           )
}

function run_prove {
    prove -lvr t

    # test with different locale
    LANG=fr_FR.utf8 prove -lvr t
}

for v in "2-x" "3-x" "4-x" "4-1" "libzmq"
do
    local_test $v
done

# extra test to verify sonames arg is honored
LD_LIBRARY_PATH="$HOME/git/zeromq2-x/src/.libs:"
LD_LIBRARY_PATH+="$HOME/git/zeromq3-x/src/.libs:"
export LD_LIBRARY_PATH

PERL5LIB=lib:$PERL5LIB perl xt/sonames.pl

