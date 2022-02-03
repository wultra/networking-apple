#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used

TOP=$(dirname $0)
SRC_ROOT="`( cd \"$TOP/..\" && pwd )`"

pushd "$SRC_ROOT"
carthage bootstrap --platform ios --platform tvos --use-xcframeworks
popd