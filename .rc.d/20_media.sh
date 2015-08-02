#!/bin/sh

##################################
# Find media files
find_media() {
  find ${2:-.} -type f -exec file -N -i -- {} + | sed -n 's!: '"${1:-video}"'/[^:]*$!!p'
}
alias find_video='find_media video'
alias find_music='find_media audio'
alias find_photos='find_media image'
