#!/bin/bash
cd "$( dirname "$BASH_SOURCE" )/.." || exit 1
PRINT_TITLE=1
. ./bin/setup.sh
wit filetype . --long --long --ignore-fst
