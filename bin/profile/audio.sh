#!/bin/sh

# Flac to MP3
flac2mp3(){
    # NOTE: see lame -V option for quality meaning
    local XCODE_MP3_QUALITY=0
    # Check commands
    if command -v ffmpeg >/dev/null; then
	for a in *.flac; do
	#find -type f -name "*.flac" -print0 | while read -d $'\0' a; do
	    ffmpeg -i "$a" -qscale:a $XCODE_MP3_QUALITY "${a%*.flac}.mp3"
	done
    elif command -v ffmpeg >/dev/null && command -v ffmpeg >/dev/null; then
	for a in *.flac; do
	#find -type f -name "*.flac" -print0 | while read -d $'\0' a; do
	    # Get the tags
	    ARTIST=$(metaflac "$a" --show-tag=ARTIST | sed s/.*=//g)
	    TITLE=$(metaflac "$a" --show-tag=TITLE | sed s/.*=//g)
	    ALBUM=$(metaflac "$a" --show-tag=ALBUM | sed s/.*=//g)
	    GENRE=$(metaflac "$a" --show-tag=GENRE | sed s/.*=//g)
	    TRACKNUMBER=$(metaflac "$a" --show-tag=TRACKNUMBER | sed s/.*=//g)
	    DATE=$(metaflac "$a" --show-tag=DATE | sed s/.*=//g)
	    # Stream flac into the lame encoder
	    flac -c -d "$a" | lame -V $XCODE_MP3_QUALITY --add-id3v2 --pad-id3v2 --ignore-tag-errors \
	    --ta "$ARTIST" --tt "$TITLE" --tl "$ALBUM"  --tg "${GENRE:-12}" \
	    --tn "${TRACKNUMBER:-0}" --ty "$DATE" - "${a%*.flac}.mp3"
	done
    fi
}

########################################
########################################
# Last commands in file
# Execute function from command line
[ $# -gt 0 ] && eval "$@"
