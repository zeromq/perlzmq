#!/bin/bash

set -e

function zmq_major {
    echo $(\
        PERL5LIB=lib:$PERL5LIB \
        perl -M'ZMQ::FFI::Util q(zmq_version)' \
        -E 'say((zmq_version)[0])'\
    )
}

function travis_test {
    sudo rm -f /usr/lib/libzmq.so /usr/lib/x86_64-linux-gnu/libzmq.so

    case $1 in
        2)
            soname='libzmq.so.1'
            sodir='/usr/lib'
            ;;
        3)
            soname='libzmq.so.3'
            sodir='/usr/lib/x86_64-linux-gnu'
            ;;
    esac

    echo -e "\n$soname"

    sudo ln -svf $soname $sodir/libzmq.so
    sudo ldconfig

    # sanity test
    ver=$(zmq_major)
    if [[ $ver != $1 ]];
    then
        echo "unexpected version $ver != $1"
        exit 1
    fi

    run_prove
}

function local_test {
    echo -e "\nlibzmq ${1}.x"
    export LD_LIBRARY_PATH="$HOME/git/zeromq$1-x/src/.libs"
    run_prove
}

function run_prove {
    prove -lvr t

    # test with different locale
    LANG=fr_FR.utf8 prove -lvr t
}

for v in 2 3
do
    if [[ -n $TRAVIS ]]
    then
        travis_test $v
    else
        local_test $v
    fi
done

if [[ -z $TRAVIS ]]
then
    LD_LIBRARY_PATH="$HOME/git/zeromq2-x/src/.libs:"
    LD_LIBRARY_PATH+="$HOME/git/zeromq3-x/src/.libs:"
    export LD_LIBRARY_PATH
fi

PERL5LIB=lib:$PERL5LIB perl xt/sonames.pl
