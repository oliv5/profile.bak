#!/bin/sh

##################################
# Find media files
find_media() {
  find ${2:-.} -type f -exec file -N -i -- {} + | sed -n 's!: '"${1:-video}"'/[^:]*$!!p'
}
alias find_video='find_media video'
alias find_music='find_media audio'
alias find_photos='find_media image'

##################################
# Idendity codec
alias lscodec='mplayer -vo null -ao null -frames 0 -identify'
alias lscodec2='mediainfo --fullscan'

# MKV to MP4
mkv2mp4() {
  ffmpeg -i "$1" -c copy -map 0 "$2"
}
