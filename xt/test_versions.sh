#!/bin/bash

set -e

function zmq_version {
    echo $(\
        PERL5LIB=lib:$PERL5LIB \
        perl -M'ZMQ::FFI::Util q(zmq_version)' \
        -E 'print join " ",zmq_version'\
    )
}

function travis_test {
    major_version=$1

    # install the libzmq version we need
    case $major_version in

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

        devel)
            tmpdir=`mktemp -d`
            git clone https://github.com/zeromq/libzmq.git $tmpdir
            ( cd $tmpdir
              ./autogen.sh
              ./configure --without-libsodium
              make -j2 )
            export LD_LIBRARY_PATH=$tmpdir/src/.libs
            ;;
    esac

    # sanity test
    ver=($(zmq_version))
    if [[ "${ver[0]}" != "$major_version" && "$major_version" != "devel" ]];
    then
        echo "unexpected version ${ver[0]} != $major_version"
        exit 1
    fi

    echo -e "\nTesting zeromq" \
        "$(echo ${ver[@]} | tr ' ' '.')"

    run_prove
}

function local_test {
    major_version=$1

    case $major_version in
        [2-4])
            export LD_LIBRARY_PATH="$HOME/git/zeromq$1-x/src/.libs"
            ;;
        devel)
            export LD_LIBRARY_PATH="$HOME/git/libzmq/src/.libs"
            ;;
    esac

    echo -e "\nTesting zeromq" \
        "$(zmq_version | tr ' ' '.')"

    run_prove
}

function run_prove {
    prove -lvr t

    # test with different locale
    LANG=fr_FR.utf8 prove -lvr t
}

for v in 2 3 4 devel
do
    if [[ -n $TRAVIS ]]
    then
        travis_test $v
    else
        local_test $v
    fi
done

# extra test to verify sonames arg is honored
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

