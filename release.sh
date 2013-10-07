#!/bin/bash

set -e

bash xt/test_versions.sh
dzil release
git push --tags
