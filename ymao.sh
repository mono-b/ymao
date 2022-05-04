#!/bin/bash

# deps: "yt-dlp" "jq" "curl" "awk" "sed"


##############################################
# Set your music dir "$HOME/path/to/music/dir"
# DO NOT ADD A '/' AT THE END OF IT
music_dir=""

# YT Var
yt_link="https://www.youtube.com"

[[ "$music_dir" == "" ]] && echo "EDIT THE SCRIPT AND ADD A MUSIC DIR!!" && exit 1

# Functions
main() {
    read -p "Artist: " artist
    read -p "Album: " album
    mkdir "$music_dir"/"$artist"/ 2> /dev/null || mkdir "$music_dir"/"$artist"/"$album"/ 2> /dev/null

    [[ ! -z $i_option ]] && read -p "Playlist's ID: " playlist || search_playlist

    yt-dlp -x \
           --audio-format mp3 \
           --add-metadata \
           -o "$music_dir/$artist/$album/%(title)s.%(ext)s" \
           --yes-playlist "$yt_link"/"$playlist"

    [[ ! -z $t_option ]] && get_album_art
    [[ ! -z $c_option ]] && convert_ogg
}

help_text() {
    cat<<EOF
 By default ymao runs semi-interactively, where the user only inserts an artist and album. The script will try to search
 the correct playlist/album and download it automatically.

 With [-i] as an option, the user needs to also introduce the playlist's ID (ex: playlist?list=PLImd94xC...)
 If running the script semi-interactively and failing, try again with [-i] as an option. This option runs
 effectively every time, as far as I have tested.

 Extra options:
     -c convert files to ogg
     -t download album art
EOF
}

search_playlist() {
    query2=$(echo "$artist $album"+album | tr ' ' '+')
    html_code=$(curl -s "https://yewtu.be/search?q=${query2}&page=1&date=none&type=playlist&duration=none&sort=relevance" | \
                sed -n '/<a style="width/,/<\/body>/p')

    unsorted_results=$(grep -Eoi "playlist\?list=.+[a-zA-Z0-9]|[0-9]+ videos|${album}.+" <<< $html_code | \
                            sed \
                            -e 's/<\/p>//' \
                            -e 's/ videos$/ songs/' \
                            -e 's/<\/b>//' \
                            -e 's/ - Invidious<\/title>//' | \
                            sed '/^[[:space:]]*$/d')

    query3=$(echo "$artist"/"$album" | tr ' ' '+')
    album_len=$(curl -s "https://www.last.fm/music/${query3}" | \
                    grep -Eo ' [0-9]+ tracks' | \
                    awk 'NR==1{print $1 " songs"}')

    playlist=$(echo "$unsorted_results" | \
               paste - -s -d'\t\t\n' | \
               head -n3 | \
               grep -E "${album_len}" | \
               head -n1 | \
               awk '{print $1}')
}

get_album_art() {
    query=$(echo "$artist $album" | tr ' ' '+')
    album_art_url=$(curl -s "https://itunes.apple.com/search?term=${query}&media=music&entity=musicTrack" \
                            | jq '.results[] | .artworkUrl60' \
                            | head -n1 | sed 's/^"//g;s/"$//g;s/60x60bb.jpg/600x600bb.jpg/g')

    curl "$album_art_url" --output "$music_dir"/"$artist"/"$album"/AlbumArt.jpg
}

convert_ogg() {
	for file in "$music_dir"/"$artist"/"$album"/*.mp3 ; do
	    OUTPUT=${file%.mp3}
	    echo "$OUTPUT"
	    ffmpeg -i "$file" "$OUTPUT.ogg"
    done
    rm -f "$music_dir"/"$artist"/"$album"/*.mp3
}

check_deps() {
    for dep; do
        if ! command -v "$dep" >/dev/null ; then
            exit_on_error "\"$dep\" is not installed.\n"
        fi
    done
}

exit_on_error () {
	printf "$*" >&2
	exit 1
}

# Options
while getopts ':hcti' opt; do
    case $opt in
        h)
        help_text
        exit 0
        ;;
        c)
        c_option=1
        ;;
        t)
        t_option=1
        ;;
        i)
        i_option=1
        ;;
        \?)
        echo "Invalid option: -$OPTARG." >&2
        exit 1
        ;;
    esac
done
shift $((OPTIND-1))

# Check dependencies and start
check_deps "yt-dlp" "curl" "jq" "awk" "sed"

main
