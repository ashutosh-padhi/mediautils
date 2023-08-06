#!/bin/bash
TEMP=$(getopt -o h::l::d: --long help::,list::,maxdepth:,human:: -- "$@")
eval set -- "$TEMP"

help(){
    cat <<EOF
-h | --help: to show this help message
-l | --list: to list all the video present
EOF
}

#---------- colors -----------
black="\033[30m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"
grey="\033[37m"
reset="\033[0m"


gen_file_list(){
    TIMESTAMP=$(date +%s)
    MOVIE_LIST="movie_list_$TIMESTAMP.csv"
    NON_MOVIE_LIST="non_movie_list_$TIMESTAMP.csv"
    echo $MOVIE_LIST > moviefile
    DEST=$*
    echo $DEST
    echo "" > $MOVIE_LIST
    echo "" > $NON_MOVIE_LIST
    find "$DEST" -type f -size +200M -exec file -N -i -- {} + | sed -n 's!: video/[^:]*$!!p' \
	| while IFS= read -r line; do
	duration=$(ffprobe -i "$line" -show_entries format=duration -v quiet -of csv="p=0")
	size=$(stat --format="%s" "$line")
	sizehuman=$(echo $size | numfmt --to=iec)
	if [ ${duration%.*} -ge 4200 ]
	then echo "$line, $(basename "$line"), $duration, $(date -d@$duration -u +%H:%M:%S), $size, $sizehuman" >> $MOVIE_LIST
	else echo "$line, $(basename "$line"), $duration, $(date -d@$duration -u +%H:%M:%S), $size, $sizehuman" >> $NON_MOVIE_LIST
	fi
    done
}

listvideo(){
    find "$1" -maxdepth $2 -type f -exec file -N -i -- {} + | sed -n 's!: video/[^:]*$!!p' \
	| while IFS= read -r line; do
	duration=$(ffprobe -i "$line" -show_entries format=duration -v quiet -of csv="p=0")
	durationhuman=""
	if [[ -n $duration ]]
	then
	   durationhuman=$(date -d@$duration -u +%H:%M:%S)
	fi
	size=$(stat --format="%s" "$line")
	sizehuman=$(echo $size | numfmt --to=iec)
	if [[ $3 = 1 ]]
	then
	    printf "$red%8s$reset $green%5s$reset  $cyan%s$reset\n" "$durationhuman" "$sizehuman" "$(basename "$line")" 
	else
	    printf "$red%10.2f$reset $green%12s$reset $cyan%s$reset\n" "$duration" "$size" "$(basename "$line")" 
	fi
    done
}

action=none
human=0
maxdepth=1
while true; do
    case "$1" in
	-h|--help)
	    help; exit;;
	-l|--list)
	    action=list; shift 2;;
	-d|--maxdepth)
	    maxdepth=$2; shift 2;;
	--human)
	    human=1; shift 2;;
	--) shift; break;;
    esac
done

if [[ $action = list ]]
then listvideo $1 $maxdepth $human
fi

