# ymao

A script to download music albums from Invidious (YT's frontend) and organize them in your music's 
interactively. It adds metadata by default and can optionally download album art covers and convert 
the audio files to `.ogg` for saving some space.

!! IMPORTANT: YOU NEED TO ADD YOUR MUSIC DIR IN THE SCRIPT, OTHERWISE IT WON'T EXECUTE !!

## Download

```
git clone https://github.com/mono-b/ymao.git
chmod +x ymao.sh
```

## Usage

```
./ymao.sh [OPTIONS]
    -h show the help text
    -t download album cover
    -c convert files to .ogg
    -i prompts for playlist (playlist?list=PL...)
```

## Dependencies

- yt-dlp 
- curl
- jq
