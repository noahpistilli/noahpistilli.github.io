#!/usr/bin/env bash
COPYRIGHT='(c) wiimm (at) wiimm.de -- 2020-12-02'

# set 40 line, 100 columns
printf '\e[8;40;100t'

cd "$( dirname "$BASH_SOURCE" )/.." || exit 1

if [[ $1 = "" ]]
then
    printf "\n\e[41;37;1m This script supports the *.desktop files!  =>  Abort! \e[0m\n" >&2
elif [[ ! -f $1 ]]
then
    printf "\n\e[41;37;1m Script not found: \e[40;33;1m %s \e[0m\n" "$1" >&2
else
    bash "$@"
fi

printf "\n\e[36;1m---  Done!  --  Press RETURN to exit.  ---\e[0m\n\n"
read -n1

