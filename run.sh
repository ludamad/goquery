#!/bin/bash
set -e

./compile.sh > .compile-log
goal/main main.lua
