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

function travis_test {
    test_version=$1

    # install the libzmq version we need
    buildzmq $test_version

    # sanity test
    ver=($(zmq_version))
    realmajor=${ver[0]}
    testmajor="$(echo $test_version | sed -e "s/-x//")"
    if [[ "$realmajor" != "$testmajor" && "$test_version" != "libzmq" ]];
    then
        echo "unexpected major version $realmajor != $testmajor"
        exit 1
    fi

    echo -e "\nTesting zeromq" \
        "$(echo ${ver[@]} | tr ' ' '.')"

    run_prove
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
}

function run_prove {
    prove -lvr t

    # test with different locale
    LANG=fr_FR.utf8 prove -lvr t
}

for v in "2-x" "3-x" "4-x" "4-1" "libzmq"
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

