#!/bin/bash

set -e

dzil build
bash xt/test_versions.sh
dzil release
