#!/usr/bin/env bash

sketchget() {
	curl --create-dirs -f -k -L -o ${2} -S -s https://sketchmaster2001.github.io/RC24_Patcher/${1}
} 

title() {
    clear
    printf "Wiimmfi Mario Kart Wii Patcher\n\n" | fold -s -w "$(tput cols)"
    printf -- "=%.0s" $(seq "$(tput cols)") && printf "\n"
}

patchmkwii() {
	title
	printf "Patching Mario Kart Wii..."
	
	sketchget "Wiimmfi-stuff/wit${sys}" wit 
	chmod +x wit
	sketchget "Wiimmfi-stuff/wszst${sys}" wszst
	chmod +x wszst
    	sketchget "Wiimmfi-stuff/bmg.tar" "bmg.tar"
    	tar -xzvf bmg.tar > /dev/null 2&1

	LANG="E F G I J K M Q S U"

    	./wit extract -vv -1p . --links --DEST work \
            --name "Mario Kart Wii (Wiimmfi)" --psel data \ -quiet -q

    	./wszst wstrt analyze --clean-dol \ -q
            "work/sys/main.dol" "work/files/rel/StaticR.rel" | sed 's/^/## /' 

    	./wszst wstrt patch "work/sys/main.dol" "work/files/rel/StaticR.rel" \
            --clean-dol --wiimmfi --all-ranks -q
	
	for lang in $LANG
    	do
		P=()
		F=./bmg/wiimmfi-$lang.txt
		[[ -f $F ]] && P=( "${P[@]}" --patch-bmg repl="$F" )
		./WSZST -q patch "work/files/Scene/UI"/*_$lang.szs --ignore "${P[@]}" -q
    	done

    	./wit copy -vv --links "work" --DEST "wiimmfi-images/Mario Kart Wii (Wiimmfi).wbfs" -q

    	finish
} 

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

cd $(dirname ${0})
patchmkwii

#Error Detection
error() {
    clear
    title "ERROR"
    print "\033[1;91mAn error has occurred.\033[0m\n\nERROR DETAILS:\n\t* Task: ${task}\n\t* Command: ${BASH_COMMAND}\n\t* Line: ${1}\n\t* Exit code: ${2}\n\n"  | fold -s -w "$(tput cols)"
	
	printf "${helpmsg}\n\n" | fold -s -w "$(tput cols)"
    
	exit
}

trap 'error $LINENO $?' ERR
set -o pipefail
set -o errtrace
