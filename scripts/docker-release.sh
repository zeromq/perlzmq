#!/bin/bash -e

docker build . \
    -t calid/zmq-ffi-testenv:1.13 \
    -t calid/zmq-ffi-testenv:latest \
    -t calid/zmq-ffi-testenv:ubuntu

for t in 1.13 latest ubuntu; do
    docker push calid/zmq-ffi-testenv:$t
done
