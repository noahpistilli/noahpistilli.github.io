#!/bin/bash
cd "$( dirname "$BASH_SOURCE" )/.." || exit 1
PRINT_TITLE=1
. ./bin/setup.sh
printf "Remove $WORKDIR\n"
[[ $WORKDIR && -d $WORKDIR ]] && rm -rf "$WORKDIR"
