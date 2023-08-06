#!/bin/bash
TEMP=$(getopt -o h::d:r:: --long help::,maxdepth:,human::,size-ge:,duration-ge:,export: -- "$@")
eval set -- "$TEMP"

help(){
    cat <<EOF
-h
--help
  : to show this help message

-d level
--maxdepth <level>
  : descend <level> of directories from the starting point

--human
  : show human friednly numbers and duration

--size-ge <size>
  : selects videos whose file size is greater than or equal
    to <size>

--duration-ge <duration>
  : selects videos whose duraiton is greater than or equal
    to <duration>

--export <file>
  : export result to a file with the name <file>
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
    startpoint=$1
    if [[ $startpoint = 0 ]]
    then
	startpoint='.'
    fi
    find "$startpoint" $depthoption -type f $sizeoption -exec file -N -i -- {} + | sed -n 's!: video/[^:]*$!!p' \
	| while IFS= read -r line; do
	duration=$(ffprobe -i "$line" -show_entries format=duration -v quiet -of csv="p=0")
	durationhuman=""
	if [[ -n $duration ]]
	then
	   durationhuman=$(date -d@$duration -u +%H:%M:%S)
	fi
	size=$(stat --format="%s" "$line")
	sizehuman=$(echo $size | numfmt --to=iec)
	filename=$(basename "$line")
	if [[ -n $durationlimit && $(echo "$duration < $durationlimit" | bc -l) = 1 ]]
	then
	    continue
	fi
	case "$action" in
	    list)
		if [[ $2 = 1 ]]
		then
	    	    printf "$red%8s$reset $green%5s$reset  $cyan%s$reset\n" "$durationhuman" "$sizehuman" "$filename" 
		else
	    	    printf "$red%10.2f$reset $green%12s$reset $cyan%s$reset\n" "$duration" "$size" "$filename" 
		fi
	    ;;
	    export)
		printf "\"%s\", \"%s\", %s, %s, %s, %s\n" "$line" "$filename" $size $sizehuman $duration $durationhuman >> $exportfile
	    ;;
	esac
    done
}

action=list
human=0
maxdepth=1
sizeoption=""
durationlimit=""
depthoption="-maxdepth 1"
recurse=0
while true; do
    case "$1" in
	-h|--help)
	    help; exit;;
	-d|--maxdepth)
	    maxdepth="-maxdepth $2"; shift 2;;
	-r)
	    recurse=1; shift 2;;
	--human)
	    human=1; shift 2;;
	--size-ge)
	    sizeoption="-size +$2"; shift 2;;
	--duration-ge)
	    durationlimit=$2; shift 2;;
	--export)
	    exportfile=$2;
	    action=export;
	    if [[ -f $exportfile ]]
	    then
		echo $exportfile already exists
		exit;
	    fi
	    shift 2;;
	--) shift; break;;
    esac
done

if [[ $recurse = 1 ]]; then depthoption=""; fi
listvideo $1 $human

