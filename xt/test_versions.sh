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

    # install the libzmq version we need
    case $1 in

        2)
            wget https://launchpad.net/ubuntu/+archive/primary/+files/libzmq1_2.1.11-1ubuntu1_amd64.deb -qO /tmp/libzmq1.deb
            sudo dpkg -i /tmp/libzmq1.deb
            ;;
        3)
            sudo add-apt-repository -y ppa:bpaquet/zeromq3-precise
            sudo apt-get -y update
            sudo apt-get -y install libzmq1
            ;;
        4)
            sudo add-apt-repository -y ppa:bpaquet/zeromq4-precise
            sudo apt-get -y update
            sudo apt-get -y install libzmq1
            ;;
    esac

    # sanity test
    ver=$(zmq_major)
    if [[ $ver != $1 ]];
    then
        echo "unexpected version $ver != $1"
        exit 1
    fi

    echo -e "\nTesting zeromq ${1}.x"
    run_prove
}

function local_test {
    echo -e "\nTesting zeromq ${1}.x"
    export LD_LIBRARY_PATH="$HOME/git/zeromq$1-x/src/.libs"
    run_prove
}

function run_prove {
    prove -lvr t

    # test with different locale
    LANG=fr_FR.utf8 prove -lvr t
}

for v in 2 3 4
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
else
    sudo dpkg -i /tmp/libzmq1.deb
    sudo apt-get -y install libzmq3
fi

PERL5LIB=lib:$PERL5LIB perl xt/sonames.pl

