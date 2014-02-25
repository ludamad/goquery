#!/bin/bash
set -e

./compile.sh
cd goal
./main --tests $@
