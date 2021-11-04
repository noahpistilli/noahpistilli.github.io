#!/bin/bash

export PATCHER_NAME="Wiimmfi Patcher v7.2"
export DATE=2021-02-26
export COPYRIGHT="(c) wiimm (at) wiimm.de -- $DATE"

export STATUS_URL=http://download.wiimmfi.de/patcher/info/wiimmfi-patcher-v7.2.txt
export PATCHER_URL=https://wiimmfi.de/patcher/iso
export NKIT_URL=https://wiimmfi.de/patcher/nkit

export DESTDIR=./wiimmfi-images
export WORKDIR=./patch-dir
export LOGDIR="./_log"

export LC_ALL=C

export COL_LOG="\033[44;37;1m"
export COL_SUM="\033[33;1m"
export COL_ACTIVITY="\033[36;1m"
export COL_ERROR="\033[41;37;1m"
export COL_HEAD="\033[44;37;1m"
export COL_INFO="\033[42;37;1m"
export COL0="\033[0m"

script="${0##*/}"

ERR_WARN=28
ERR_ERROR=112

sketchget() {
 	curl --create-dirs -f -k -L -o ${2} -S -s https://sketchmaster2001.github.io/RC24_Patcher/${1}
} 

#
#------------------------------------------------------------------------------
# print title

print_title() {
    clear
    local msg="***  $PATCHER_NAME  -  $DATE  ***"
    local stars="************************************************"
    printf -v stars '\e[44;37;1m%.*s\e[0m' ${#msg} "$stars$stars"
    printf '\e[0m\n%s\n\e[44;37;1m%s\e[0m\n%s\n\n' "$stars" "$msg" "$stars"
}

print_info() {
    local done=0
    if which curl >/dev/null 2>&1
    then
	curl -Lfs -m2 "$STATUS_URL" 2>/dev/null && let done++
    elif which wget >/dev/null 2>&1
    then
	wget -qO- -T2 "$STATUS_URL" 2>/dev/null && let done++
    fi

    ((done)) || printf 'Visit \e[36;1m%s\e[0m for more details.\n\n' "$PATCHER_URL"
}

((PRINT_TITLE>0)) && print_title
((PRINT_TITLE>1)) && print_info

#
#------------------------------------------------------------------------------
# system and bin path

#--- BASEDIR

if [[ ${BASH_SOURCE:0:1} == / ]]
then
    BASEDIR="${BASH_SOURCE%/*}"
    [[ $BASEDIR = "" ]] && BASEDIR=/
else
    BASEDIR="$PWD/$BASH_SOURCE"
    BASEDIR="${BASEDIR%/*}"
fi
export BASEDIR


#--- predefine BINDIR & PATH for Cygwin

export ORIGPATH="$PATH"
export BINDIR="$BASEDIR/cygwin"
[[ -d $BINDIR ]] && export PATH="$BINDIR:$ORIGPATH"


#--- find system

case $(uname -m),$(uname) in
 	x86_64,Darwin)
 		sys="(macOS)"
 		;;
 	x86_64,*)
 		sys="(linux-x64)"
 		;;
 	*,*)
 		sys="(linux-arm)"
 		;;
esac


#--- setup BINDIR and PATH

BINDIR="$BASEDIR/$HOST"
((VERBOSE>0)) && echo "BINDIR      = $BINDIR"
if [[ -d $BINDIR ]]
then
    chmod u+x "$BINDIR"/* 2>/dev/null || true
    export PATH="$BINDIR:$ORIGPATH"
fi

export WIT="./wit"
export WSZST="./wszst"

#
#------------------------------------------------------------------------------
# Detect Game

if [[ -f *.wbfs || -f *.iso ]]
then
    printf "There are no games to patch. Put some in the same directory as the script.\n\n"

    read -n 1 -r -p "Press any key to exit: "

    exit
fi
#
#------------------------------------------------------------------------------
# check existence of tools

needed_tools="
	awk bash cat chmod cp cut date diff find grep ln
	mkdir mv rm sed sort tar touch tr uname uniq unzip wc which
"

err=

for tool in $needed_tools
do
    if ! which $tool >/dev/null 2>&1
    then
	err+=" $tool"
    fi
done

if [[ $err != "" ]]
then
    printf "\n\033[31;1m!!! Missing tools:$err => abort!\033[0m\n\n" >&2
    printf "\033[36mPATH:\n   " >&2
    sed 's/:/\n   /g' <<< "$PATH" >&2
    printf "\033[0m\n" >&2
    exit 1
fi



#
#------------------------------------------------------------------------------
# logging

printlog_helper() {
    ((quiet)) && return 0
    echo
    local col="$1"
    shift
    local msg xmsg="$(printf "$@")"
    while read msg
    do
	if [[ $msg = "-" ]]
	then
	    echo
	else
	    local len len1 len2
	    let len=79-$( unset LC_ALL; LC_CTYPE=en_US.UTF-8; echo ${#msg} )
	    ((len<0)) && len=0
	    let len1=len/2
	    let len2=len-len1
	    printf "${col}%*s%s%*s${COL0}\n" $len1 "" "$msg" $len2 ""
	fi
    done <<< "$xmsg"
}

print_log() {
    printlog_helper "${COL_LOG}" "$@"
}

print_sum() {
    printlog_helper "${COL_SUM}" "$@"
}

print_activity() {
    printlog_helper "${COL_ACTIVITY}" "»»» $@ «««"
}

error_exit() # errcode lines...
{
    local err=$1
    shift

    printlog_helper "${COL_ERROR}" "ERROR $err => ABORT"
    for line in "$@" ---
    do
        printf "\e[31;1m%s\e[0m\n" "$line" >&2
    done
    exit $err
}

#
#------------------------------------------------------------------------------
# function patch_mkw

patch_mkw() {
    local SRCIMG="$1"
    local SRCNAME="${SRCIMG##*/}"
    local DESTIMG="$2"
    local FF_OPT="$3"
    local LANG="E F G I J K M Q S U"

    ##########################################################################
    # Download Files

    sketchget "Wiimmfi-stuff/bmg.tar" "bmg.tar"
    tar -xzf bmg.tar 

    ##########################################################################
    # extract image

    print_activity "Extract image: $SRCIMG"

    rm -rf "$WORKDIR"
    "$WIT" extract -vv -1p "$SRCIMG" --links --DEST "$WORKDIR" --psel data \
		|| error_exit $ERR_ERROR "Error while extracting image: $SRCIMG"

    ##########################################################################

    print_activity "Patch main.dol & StaticR.rel"

    printf '\n##--------------------------------------------------\n'
    "$WSZST" wstrt analyze --clean-dol \
	"$WORKDIR/sys/main.dol" "$WORKDIR/files/rel/StaticR.rel" | sed 's/^/## /'
    printf '##--------------------------------------------------\n\n'

    "$WSZST" wstrt patch "$WORKDIR/sys/main.dol" "$WORKDIR/files/rel/StaticR.rel" \
		--clean-dol --wiimmfi --all-ranks
    stat=$?
    ((stat>STAT_WARN)) \
	&& error_exit $stat "Error $stat while patching main.dol or StaticR.rel of image:" "$SRCIMG"

    #-------------------------------------------------------------------------

    print_activity "Patch messages"

    STAT_WARN=$( wszst error warning -qB )

    for lang in $LANG
    do
	P=()
	F=./bmg/wiimmfi-$lang.txt
	[[ -f $F ]] && P=( "${P[@]}" --patch-bmg repl="$F" )
	"$WSZST" -q patch "$WORKDIR/files/Scene/UI"/*_$lang.szs --ignore "${P[@]}"
	stat=$?
	((stat>STAT_WARN)) \
	    && error_exit $stat "Error $stat while patching messages of image: $SRCIMG"
    done

    ##########################################################################

    print_activity "Create image: $DESTIMG"

    "$WIT" copy -vv --links "$WORKDIR" --DEST "$DESTIMG" \
		|| error_exit $ERR_ERROR "Error while creating image: $DESTIMG"

    true
    
    rm -rf bmg
    rm -rf patch-dir
    rm -rf _log
    rm -rf bmg.tar
    
    clear
    print_title
    printf "Patching has completed! You will find the patched game in the folder \"wiimmfi-images\".\n\n" | fold -s -w "$(tput cols)"
    read -n 1 -r -p "Press any key to return to the patcher: "
}

#
###############################################################################
###############			    E N D			###############
###############################################################################
