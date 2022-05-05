#!/bin/bash

# deps: "yt-dlp" "jq" "curl" "awk" "sed"


##############################################
# Set your music dir "$HOME/path/to/music/dir"
# DO NOT ADD A '/' AT THE END OF IT
music_dir=""

[[ "$music_dir" == "" ]] && echo "EDIT THE SCRIPT AND ADD A MUSIC DIR!!" && exit 1

# Vars
yt_url="https://youtube.com"

# Functions
main() {
    read -p "Artist: " artist
    read -p "Album: " album
    final_dir="$music_dir"/"$artist"/"$album"
    artist_query=$(tr ' ' '+' <<< "$artist")
    album_query=$(tr ' ' '+' <<< "$album")
    mkdir "$music_dir"/"$artist"/ 2> /dev/null || mkdir "$final_dir"/ 2> /dev/null
    [[ ! -z $i_option ]] && read -p "Playlist's ID: " playlist || search_playlist
    yt-dlp -x --audio-format mp3 --add-metadata -o "$final_dir/%(title)s.%(ext)s" --yes-playlist "$yt_url"/"$playlist"
    [[ ! -z $t_option ]] && get_album_art
    [[ ! -z $c_option ]] && convert_ogg
}

search_playlist() {
    invidious_url="https://yewtu.be/search?q=$artist_query+$album_query+album&page=1&date=none&type=playlist&duration=none&sort=relevance"
    lastfm_url="https://www.last.fm/music/$artist_query/$album_query"
    album_len=$(curl -s "$lastfm_url" | grep -Eo ' [0-9]+ tracks' | awk 'NR==1{print $1 " songs"}')
    playlist=$(curl -s "$invidious_url" | grep -Eoi "playlist\?list=.+[a-zA-Z0-9]|[0-9]+ videos" |
    sed 's/ videos$/ songs/g' | paste - -s -d'\t\n' | grep -E "${album_len}" | awk 'NR==1 {print $1}')
}

get_album_art() {
    album_cover_url="https://itunes.apple.com/search?term=$artist_query+$album_query&media=music&entity=musicTrack"
    curl -o "$final_dir"/AlbumArt.jpg "$(curl -s "$album_cover_url" | jq '.results[] | .artworkUrl60' | head -n1 | sed 's/^"//g;s/"$//g;s/60x60bb.jpg/600x600bb.jpg/g')"
}

convert_ogg() {
	for file in "$final_dir"/*.mp3
    do
	    OUTPUT=${file%.mp3}
	    echo "$OUTPUT"
	    ffmpeg -i "$file" "$OUTPUT.ogg"
    done
    rm -f "$final_dir"/*.mp3
}

check_deps() {
    for dep
    do
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
while getopts ':cti' opt; do
    case $opt in
        c) c_option=1 ;;
        t) t_option=1 ;;
        i) i_option=1 ;;
        \?) echo "Invalid option: -$OPTARG." >&2 ; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# Check dependencies and start
check_deps "yt-dlp" "curl" "jq" "awk" "sed"

main
