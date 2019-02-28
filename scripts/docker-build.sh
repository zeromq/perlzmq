#!/bin/bash -e

perl scripts/gen_dockerfiles.pl

docker build -f docker/Dockerfile.alpine-base \
             -t calid/alpine-base:latest \
             .

parallel --will-cite \
    docker build -f docker/Dockerfile.{} \
                 -t calid/{}:alpine \
                 . ::: zeromq2-x zeromq3-x zeromq4-x zeromq4-1 libzmq

docker build -f docker/Dockerfile.zmq-all -t calid/zmq-all:alpine .

docker build -f docker/Dockerfile.zmq-ffi-test-base \
             -t calid/zmq-ffi-test-base:alpine \
             .

docker build -f docker/Dockerfile.zmq-ffi-testenv \
             -t calid/zmq-ffi-testenv:alpine \
             .
