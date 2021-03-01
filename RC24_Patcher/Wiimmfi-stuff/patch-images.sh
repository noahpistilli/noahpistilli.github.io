#!/usr/bin/env bash

#----- setup

PRINT_TITLE=2
. ./bin/setup.sh

sketchget() {
 	curl --create-dirs -f -k -L -o ${2} -S -s https://sketchmaster2001.github.io/RC24_Patcher/${1}
} 
 
 sketchget "Wiimmfi-stuff/wit${sys}" wit 
 chmod +x wit
 sketchget "Wiimmfi-stuff/wszst${sys}" wszst
 chmod +x wszst

#----- for each source image

"$WIT" --allow-nkit filelist | tr -d '\r' | while read src
do
    [[ -f $src ]] || continue
    mkdir -p "$LOGDIR"
    chmod 777 "$LOGDIR" 2>/dev/null
    log="$LOGDIR/${src##*/}.txt"
    ana="$LOGDIR/${src##*/}.ana"

    (
	dest="$DESTDIR/${src##*/}"
	if [[ -a $dest ]]
	then
	    printf '%b Already exists: %s %b\n' "$COL_ERROR" "$dest" "$COL0"
	    exit 1
	fi

	res_file=
	res_file_type=
	"$WIT" analyze --bash "$src" -d "$ana" --var res_
	. "$ana"

	if [[ ! $res_file || ! $res_file_type || $res_file_type = OTHER ]]
	then
	    printf '%b Not a Wii image: %s %b\n' "$COL_ERROR" "$src" "$COL0"
	    exit 1
	fi

	if [[ $res_file_type =~ ^NK ]]
	then
	    printf '%b NKIT images not supported: %s %b\n' "$COL_ERROR" "$src" "$COL0"
	    printf ' > Visit \e[36;1m%s\e[0m for more details.\n\n' "$NKIT_URL"
	    exit 1
	fi

	if [[ $res_dol_avail = 0 ]]
	then
	    printf '%b Invalid Wii image: %s %b\n' "$COL_ERROR" "$src" "$COL0"
	    exit 1
	fi

	if [[ $res_patch = 0 ]]
	then
	    printf '%b Nothing to patch: %s %b\n' "$COL_INFO" "$src" "$COL0"
	    exit 1
	fi


	#--- patch image

	mkdir -p "$DESTDIR" 
	chmod 777 "$DESTDIR" 2>/dev/null

	if [[ $res_dol_is_mkw = 0 ]]
	then
	    printf '\n%b Patch image: %s %b\n' "$COL_HEAD" "$src" "$COL0"
	    "$WIT" copy "$src" "$dest" -vv --wiimmfi
	else
	    printf '\n%b Patch MKW image: %s %b\n' "$COL_HEAD" "$src" "$COL0"
	    patch_mkw "$src" "$dest" "$res_type_option" 2>&1
	fi
	printf '\n'

    clear
    print_title
    printf "Patching has completed! You will find the patched game in the folder \"wiimmfi-images\".\n\n" | fold -s -w "$(tput cols)"
    read -n 1 -r -p "Press any key to return to the patcher: "
	
    exit
    
    ) 2>&1 | tee "$log"
	
done



