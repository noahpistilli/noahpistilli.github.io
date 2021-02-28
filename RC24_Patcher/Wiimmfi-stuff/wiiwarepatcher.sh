#!/usr/bin/env bash

sketchget() {
	curl --create-dirs -f -k -L -o ${2} -S -s https://sketchmaster2001.github.io/RC24_Patcher/${1}
} 

title() {
    clear
    printf "Wiimmfi WiiWare Patcher\tBy: Noah Pistilli\n" | fold -s -w "$(tput cols)"
    printf -- "=%.0s" $(seq "$(tput cols)") && printf "\n\n"
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

title

sketchget "Wiimmfi-stuff/lzx${sys}" "lzx"
chmod +x lzx
sketchget "Wiimmfi-stuff/wiiwarepatcher${sys}" "wiiwarepatcher"
chmod +x wiiwarepatcher

if [ ! -f *.wad ]
then
    printf "There are no wads to patch. Put some in the same directory as the script.\n\n"
    
    read -n 1 -r -p "Press any key to exit: "
    
    exit
fi

mkdir -p "wiimmfi-images"
mkdir -p "backup-wads"

for f in *.wad
do
	echo "Processing $f..."
	echo "Making backup..."
	cp "$f" "backup-wads"
	echo "Patching... This might take a second."
	./sharpii WAD -u "$f" "temp"
	mv temp/00000001.app 00000001.app
    	./wiiwarepatcher
	mv 00000001.app temp/00000001.app
	rm "$f"
	./sharpii WAD -p "temp" "./wiimmfi-images/${f}-Wiimmfi"
	rm -rf "temp"
	
	title
	printf "Patching has completed! You will find the patched game in the folder \"wiimmfi-images\".\n\n"
	read -n 1 -r -p "Press any key to return to the patcher: "
	
done 
