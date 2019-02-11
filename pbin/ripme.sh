#!/bin/bash
# Note: need to fix the \" errors around filenames

# Ensure an almost clean exit
# Enable errors before
ExitHandler() {
  set +e
  # Clean up device information file
  rm "$DEVINFO" 2>/dev/null
  # Log conclusion
  echo >&2 "[ripme] End at $(date)"
  # Release mutex & exit
  rm "$PIDFILE" 2>/dev/null
  # Kill running binaries
  kill -s ${2:-TERM} -- -$$ 2>/dev/null
  # The end
  killall -q -s ${2:-TERM} ripme ripme.sh
  kill -s ${2:-TERM} $$
  exit $1
}

# Check output filename to prevent overwrites
CheckOutputFilename() {
  eval local FILEPATH=\$$1
  if [ -f "$FILEPATH" -a -z "$OVERWRITE" ]; then
    if [ ! -z "$RENAME" ]; then
      while [ -f "$FILEPATH" ]; do
        RANDOM=$(hexdump -n 2 -e '/2 "%u"' /dev/urandom)
        eval FILEPATH=\$$1
        FILEPATH="${FILEPATH%.*}.$RANDOM.${FILEPATH##*.}"
      done
    else
      return 1
    fi
  fi
  eval $1="$FILEPATH" 2>/dev/null
  return 0
}

# Init main variables
VERSION=1.21
TYPE="auto"
DEVICE=""
TRACKS="longest"
ODIR="."
ADIR=""
TITLE=""
DRYRUN=""
SLANGS=""
ALANGS="en"
SPEED=""
RENAME=""
OVERWRITE=""
USERNAME=""
DELTMP=""
METHOD="mplayer"
MPLAYER_LIB="dvdnav"
MPLAYER_OPT=""
CODEC="ogg"
DEVINFO="/tmp/$(basename $0).$(date +%s).tmp"
SPEED_DVD=(1 2 4 8 12 16)
SPEED_CD=(1 2 4 8 12 24)

# Get command line options
while getopts :t:d:e:m:o:i:u:f:x:c:s:a:rwnzk OPTNAME
do case "$OPTNAME" in
  t)  TYPE="$OPTARG";;
  d)  DEVICE="$OPTARG";;
  e)  SPEED="$(($OPTARG - 1))";;
  m)  METHOD="$OPTARG";;
  o)  ODIR="$OPTARG";;
  i)  ADIR="$OPTARG";;
  u)  USERNAME="$OPTARG";;
  f)  TITLE="$OPTARG";;
  x)  TRACKS="$OPTARG";;
  c)  CODEC="$OPTARG";;
  s)  SLANGS="$OPTARG";;
  a)  ALANGS="$OPTARG";;
  r)  RENAME="1"; OVERWRITE="";;
  w)  OVERWRITE="1"; RENAME="";;
  n)  DRYRUN="echo";;
  z)  DELTMP="true";;
  k)  ExitHandler 0 KILL;;
  [?]) echo >&2 "Ripme $VERSION - rips dvd, audio cd, extracts subtitles"
       echo >&2 "Usage: $(basename $0) [options]"
       echo >&2 "-t type    Media type: (auto), dvd, cdda"
       echo >&2 "-d device  Device name in /dev (/dev/dvd)"
       echo >&2 "-e speed   Device read speed : 1, (2), ..."
       echo >&2 "-m method  Ripping method: tccat, (mplayer), mplayer_dvdnav, mplayer_dvdread, vlc, cdparanoia"
       echo >&2 "-o dir     Output directory (current)"
       echo >&2 "-i dir     Audio output directory override (none)"
       echo >&2 "-f file    Output filename (media title)"
       echo >&2 "-x tracks  Track numbers: all, disc, (longest), 0, 1, 2,..."
       echo >&2 "-c codec   Audio codec: mp3, flac, aac, mpc, (ogg); Video codec: not used"
       echo >&2 "-s langs   DVD subtitles languages: en, fr, es, ... (none)"
       echo >&2 "-a langs   DVD audio languages: (en),fr,es,... - only with vlc"
       echo >&2 "-r         Rename existing output file (disabled). Exclusive with -w"
       echo >&2 "-w         Allow output file overwrite (disabled). Exclusive with -r"
       echo >&2 "-n         No dump, simulate only"
       echo >&2 "-z         Keep temporary files"
       echo >&2 "-k         Kill all ripme processes"
       exit 1;;
  esac
done
ARGS="$@"
shift $(expr $OPTIND - 1)
unset OPTNAME OPTARG

# Mutex exclusion
PIDFILE="/tmp/ripme.pid"
exec 200>"$PIDFILE" || exit 1
flock -n 200 || exit 1
echo $$ 1>&200

# Log preamble
echo >&2 "[ripme] Start at $(date)"
echo >&2 "[ripme] Command-line: ripme.sh $ARGS"
echo >&2 "[ripme] Video output directory: ${ODIR}"
echo >&2 "[ripme] Audio output directory: ${ADIR}"
echo >&2 "[ripme] By user: $USER"
echo >&2 "[ripme] For user: ${USERNAME:-$USER}"
touch "$DEVINFO"

# List used software
echo >&2 "[ripme] Using the following packages:"
echo >&2 "  vlc mplayer cdparanoia"
echo >&2 "  oggenc lame flac mpc ffmpeg"
echo >&2 "  transcode subtitleripper"
echo >&2 "  ppa:ruediger-c-plusplus/vobsub2srt libavutil-dev libtiff4-dev"
echo >&2 "  libtesseract-dev tesseract-ocr-eng tesseract-ocr-fra"
echo >&2 "  qpxtool cdvdcontrol hdparm eject"

# Read DVD information
if [ "$TYPE" = "auto" -o "$TYPE" = "dvd" ]; then
  DEVICE="${DEVICE:-/dev/dvd}"
  lsdvd -x "$DEVICE" > "$DEVINFO" 2>/dev/null
  if [ $? -eq 0 ]; then
    TYPE="dvd"
    echo >&2 "[ripme] Detected DVD media in device '$DEVICE'"
  elif [ "$TYPE" = "dvd" ]; then
    echo >&2 "[ripme] Error: cannot read DVD information from device '$DEVICE'..."
    ExitHandler 1
  fi
fi

# Read audio CD information
if [ "$TYPE" = "auto" -o "$TYPE" = "cdda" ]; then
  DEVICE="${DEVICE:-/dev/cdrom}"
  cdrecord dev="$DEVICE" -toc > "$DEVINFO" 2>/dev/null
  if [ $? -eq 0 ]; then
    TYPE="cdda"
    echo >&2 "[ripme] Detected audio CD media in device '$DEVICE'"
  elif [ "$TYPE" = "cdda" ]; then
    echo >&2 "[ripme] Error: cannot read audio CD information from device '$DEVICE'..."
    ExitHandler 1
  fi
  # Get audio output directory
  if [ ! -z "$ADIR" ]; then
    ODIR="$ADIR"
  fi
fi

# Check device presence. Failure if not detected
if [ ! -z "$DEVICE" -a ! -e "$DEVICE" ]; then
  echo >&2 "[ripme] Error: device '$DEVICE' is unknown..."
  ExitHandler 1
fi

# Create output directory. Failure when not existent
echo >&1 "Using output directory '$ODIR'"
mkdir -p "$ODIR"
if [ ! -d "$ODIR" ]; then
  echo >&2 "[ripme] Error: directory '$ODIR' cannot be created..."
  ExitHandler 1
fi

# Mplayer specific options
if [ "${METHOD%%_*}" = "mplayer" ]; then
  # DVD processing lib: libdvdnav (dvdnav) or libdvdread (dvd)
  MPLAYER_LIB="${METHOD##*_}"
  if [ "${METHOD##*_}" = "dvdread" ]; then
    MPLAYER_LIB="dvd"
  else
    MPLAYER_LIB="dvdnav"
    MPLAYER_OPT="-nocache"
  fi
  # Mplayer needs a home (!!)
  export MPLAYER_HOME="$(mktemp -d)"
  METHOD="mplayer"
fi

# Set device speed
if [ -n "$SPEED" ]; then
  # see http://hektor.umcs.lublin.pl/~mikosmul/computing/tips/cd-rom-speed.html
  # see http://manpages.ubuntu.com/manpages/precise/man1/cdvdcontrol.1.html
  SPEED=${SPEED_DVD[$SPEED]}
  if [ "$METHOD" != "mplayer" ]; then
    sudo hdparm -E $SPEED "$DEVICE" || \
    sudo eject -x $SPEED "$DEVICE" || \
    sudo cdvdcontrol -d "$DEVICE" -s --silent on --sm-dvd-rd $SPEED --sm-cd-rd $SPEED --sm-nosave
  fi
fi

# Main processing
if [ "$TYPE" = "dvd" ]; then

  # Extract DVD title
  if [ -z "$TITLE" ]; then
    TITLE=$(awk '/Disc Title/ {print $3}' "$DEVINFO")
    if [ -z "$TITLE" ]; then
      echo >&2 "[ripme] Error: cannot get DVD title..."
      ExitHandler 1
    fi
  fi

  # Select DVD tracks
  MAINTRACK=$(awk '/Longest track:/ {print $3}' "$DEVINFO")
  if [ -z "$MAINTRACK" ]; then
    echo >&2 "[ripme] Error: cannot get DVD tracks..."
    ExitHandler 1
  fi
  if [ "$TRACKS" = "disc" ]; then
    TRACKS=""
  elif [ "$TRACKS" = "longest" ]; then
    TRACKS="$MAINTRACK"
  elif [ "$TRACKS" = "all" ]; then
    TRACKS=$(awk -F ' |,' '/^Title: / {print $2}' "$DEVINFO")
  fi

  # Rip it
  for TRACK in ${TRACKS:-""}; do
    # Choose the output file name
    if [ "$TRACK" = "$MAINTRACK" ]; then
      DUMPFILE="${ODIR}/${TITLE}${TRACK:+_$TRACK}_main.vob"
    else
      DUMPFILE="${ODIR}/${TITLE}${TRACK:+_$TRACK}.vob"
    fi

    # Check the output file name
    if ! CheckOutputFilename "DUMPFILE"; then
      echo >&2 "[ripme] Dump: skip existing file '$DUMPFILE'..."
      continue
    fi

    # Choose the dump method: tccat, vlc, mplayer
    if [ "$METHOD" = "mplayer" ]; then

      # Proceed with the dump
      $DRYRUN mplayer -quiet -input nodefault-bindings -noconsolecontrols -nolirc ${SPEED:+-dvd-speed $SPEED} ${MPLAYER_LIB}://${TRACK} ${DEVICE:+-dvd-device "$DEVICE"} ${MPLAYER_OPT} -dumpstream -dumpfile "$DUMPFILE"

    elif [ "$METHOD" = "vlc" ]; then

      # Fix the output filename: vlc settings produces a mpeg file
      DUMPFILE="${DUMPFILE%.*}.mpg"

      # Proceed with the dump
      if [ -z "$SLANGS" ]; then
        $DRYRUN cvlc dvd://${DEVICE}#${TRACK} --audio-language=${ALANGS} --sout="#std{access=file,mux=ts,dst='${DUMPFILE}'}"
      else
        $DRYRUN cvlc dvd://${DEVICE}#${TRACK} --audio-language=${ALANGS} --sub-language=${SLANGS} --sout="#transcode{vcodec=mpgv,vb=12000,scodec=dvbs,soverlay}:std{access=file,mux=ts,dst='${DUMPFILE}'}"
      fi

    else # tccat dump method

      # Set the trap signal
      trap "ExitHandler 2" 2

      # Extract subtitles palette
      if [ ! -z "$SLANGS" ]; then
        TMP="/tmp/tmp_$(basename ${0%.*})"
        $DRYRUN mencoder dvd://${TRACK} ${DEVICE:+-dvd-device "$DEVICE"} -endpos 0 -nosound -ovc frameno -sid 0x20 -vobsubout "$TMP" -o /dev/null >/dev/null 2>&1
        PALETTE="$(grep palette \"$TMP.idx\" 2>/dev/null)"
        $DRYRUN $DELTMP rm "$TMP.idx" "$TMP.sub"
      fi

      # Prepare subtitles extraction
      FIFOS=""
      if [ ! -z "$PALETTE" ]; then
          for LANG in ${SLANGS//,/ }; do
            SUBFILE="${DUMPFILE%.*}_${LANG}"
            SUBFILESUB="$SUBFILE.sub"
            if CheckOutputFilename "SUBFILESUB"; then
              SUBINDEX=$(awk -F ' |,' '/Subtitle:.*Language: '$LANG'/ {print $14}' "$DEVINFO" | head -n 1)
              if [ ! -z "$SUBINDEX" ]; then
                FIFO="/tmp/fifo_$(basename ${0%.*})_$LANG"
                FIFOS="$FIFO $FIFOS"
                $DRYRUN rm -f "$FIFO" "$SUBFILE.*" 2>/dev/null
                $DRYRUN mkfifo "$FIFO" 2>/dev/null
                $DRYRUN sh -c " \
                  mencoder \"$FIFO\" -nosound -ovc frameno -sid $SUBINDEX -vobsubout \"$SUBFILE\" -vobsuboutid $LANG -o /dev/null ; \
                  sed -i '2i$PALETTE' \"$SUBFILE.idx\" ; \
                  vobsub2srt --lang $LANG \"$SUBFILE\" ; \
                  sed -ri -e 's/\|/l/g' -e 's/ l$/ ?/' -e 's/\.7$/?/' -e 's/^([^0-9].*)7$/\1 ?/' \"$SUBFILE.srt\" ; \
                  " &
              else
                echo >&2 "[ripme] Warning: cannot find subtitle '$LANG'..."
              fi
            else
              echo >&2 "[ripme] Dump: skip existing subtitle file '$SUBFILESUB'..."
            fi
          done
      else
        echo >&2 "[ripme] Warning: couldn't retrieve subtitle palette, cancel subtitle extraction..."
      fi

      # Dump everything
      if [ ! -z "$DUMPFILE" -o ! -z "$FIFOS" ]; then
        $DRYRUN tccat -i "$DEVICE" -T ${TRACK},-1 | tee $FIFOS > "${DUMPFILE:-/dev/null}"
      fi

      # cleanup
      if [ ! -z "$FIFOS" ]; then
        $DRYRUN rm -f "$FIFOS" 2>/dev/null
      fi

    fi

    # Wait for children
    wait

    # Set output files/directory ownership
    if [ ! -z "$DUMPFILE" ]; then
      [ -n "$USERNAME" ] && $DRYRUN chown -R "$USERNAME" "$ODIR" "$DUMPFILE"
    fi

  done

elif [ "$TYPE" = "cdda" ]; then

  # Extract audio CD tracks
  FIRST=$(awk '/first:/ {print $2}' "$DEVINFO")
  LAST=$(awk '/last/ {print $4}' "$DEVINFO")
  LENGTH=$(awk "/track: +${LAST}/ {print "'$7}' "$DEVINFO")
  if [ -z "$FIRST" -o -z "$LAST" -o -z "$LENGTH" ]; then
    echo >&2 "[ripme] Error: cannot get audio CD tracks..."
    ExitHandler 1
  fi
  echo >&2 "[ripme] Found $(($LAST-$FIRST+1)) tracks for a total length of $LENGTH"

  # Select audio CD tracks
  if expr "$TRACKS" : '-\?[0-9]\+$' >/dev/null; then
    FIRST="$TRACKS"
    LAST="$TRACKS"
  fi

  # Create output directory
  ODIR="$(echo "${ODIR}/${TITLE:-AudioCD}_${LENGTH}" | tr ':' '_')"
  mkdir -p "$ODIR"
  if [ ! -d "$ODIR" ]; then
    echo >&2 "[ripme] Error: directory '$ODIR' cannot be created..."
    ExitHandler 1
  fi

  # Set the trap signal
  trap "ExitHandler 2" 2

  # Rip it
  for TRACK in $(seq $FIRST $LAST); do
    # Build track filename
    DUMPFILE="${ODIR}/track${TRACK}.${CODEC}"
    TMPFILE="/tmp/track${TRACK}.${CODEC}.wav"

    # Check the output file name
    if ! CheckOutputFilename "DUMPFILE"; then
      echo >&2 "[ripme] Dump: skip existing file '$DUMPFILE'..."
      continue
    fi

    # Rip CD to wav
    if [ "$METHOD" = "cdparanoia" ]; then
      $DRYRUN cdparanoia ${TRACK} -d "${DEVICE}" "${TMPFILE}"
    elif [ "$METHOD" = "vlc" ]; then
      # https://wiki.videolan.org/VLC_HowTo/Extract_audio/#The_VLC_command_invocation
      $DRYRUN cvlc -I dummy --no-sout-video --sout-audio --no-sout-rtp-sap --no-sout-standard-sap --ttl=1 --sout-keep \
        --sout "#transcode{acodec=s16l,channels=2}:std{access=file,mux=wav,dst='${TMPFILE}'}" \
        cdda://${DEVICE} --cdda-track=${TRACK} vlc://quit
    else
      $DRYRUN mplayer -quiet -input nodefault-bindings -noconsolecontrols -nolirc ${SPEED:+-cdda speed=$SPEED:paranoia=2} cdda://${TRACK} ${DEVICE:+-cdrom-device "$DEVICE"} -benchmark -vc null -vo null -ao pcm:fast:waveheader:file="$TMPFILE"
    fi
    
    # Encode from wav
    if [ "$CODEC" = "mp3" ]; then
      $DRYRUN sh -c "lame --replaygain-accurate -q 0 --vbr-new -V 3 \"${TMPFILE}\" \"${DUMPFILE}\" && ${DELTMP} rm -v \"${TMPFILE}\"" &
    elif [ "$CODEC" = "aac" ]; then
      $DRYRUN sh -c "ffmpeg -acodec libfaac -i \"${TMPFILE}\" \"${DUMPFILE}\" && ${DELTMP} rm -v \"${TMPFILE}\"" &
    elif [ "$CODEC" = "mpc" ]; then
      $DRYRUN sh -c "mpcenc --quality 9 \"${TMPFILE}\" \"${DUMPFILE}\" && ${DELTMP} rm -v \"${TMPFILE}\"" &
    elif [ "$CODEC" = "flac" ]; then
      $DRYRUN sh -c "flac -8 \"${TMPFILE}\" -o \"${DUMPFILE}\" && ${DELTMP} rm -v \"${TMPFILE}\"" &
    else
      $DRYRUN sh -c "oggenc -q 7 \"${TMPFILE}\" -o \"${DUMPFILE}\" && ${DELTMP} rm -v \"${TMPFILE}\"" &
    fi
  done

  # Wait for children
  wait

  # Set output files/directory ownership
  [ -n "$USERNAME" ] && $DRYRUN chown -R "$USERNAME" "$ODIR"

elif [ "$TYPE" = "auto" ]; then

  echo >&2 "[ripme] Error: cannot identify media type..."
  ExitHandler 1

else
  echo >&2 "[ripme] Error: device type '$TYPE' is not supported..."
fi

# Exit
ExitHandler 0

----------------------------------------------
# Alternate method to dumb subtitles
# Dump subtitles
for LANG in ${SLANGS//,/ }; do
  SUBFILE="${DUMPFILE%.*}_${LANG}"
  if [ ! -e "$SUBFILE.sub" -o ! -z "$OVERWRITE" ]; then
    SUBINDEX=$(awk -F ' |,' '/Subtitle:.*Language: '$LANG'/ {print $14}' "$DEVINFO" | head -n 1)
    if [ ! -z "$SUBINDEX" ]; then
      $DRYRUN rm "$SUBFILE.*" 2>/dev/null
      $DRYRUN mencoder dvd://${TRACK} ${DEVICE:+-dvd-device "$DEVICE"} -nosound -ovc frameno -sid $SUBINDEX -vobsubout "$SUBFILE" -vobsuboutid $LANG -o /dev/null 2>/dev/null
      if [ -s "$SUBFILE.sub" ]; then
        echo >&2 "[ripme] Dump: failed to extract subtitles, try alternative method..."
        $DRYRUN sh -c "tccat -i \"$DEVICE\" -T ${TRACK},-1 | tcextract -x ps1 -t vob -a $SUBINDEX > \"$SUBFILE.tmp\""
        $DRYRUN subtitle2vobsub -p "$SUBFILE.tmp" -o "$SUBFILE"
        $DRYRUN rm "$SUBFILE.tmp"
      fi
      $DRYRUN sh -c " \
        vobsub2srt --lang $LANG \"$SUBFILE\" ; \
        sed -ri -e 's/\|/l/g' -e 's/ l$/ ?/' -e 's/\.7$/?/' -e 's/^([^0-9].*)7$/\1 ?/' \"$SUBFILE.srt\" ; \
        " &
    else
      echo >&2 "[ripme] Warning: cannot find subtitle '$LANG'..."
    fi
  else
    echo >&2 "[ripme] Dump: skip existing subtitle file '$SUBFILE.sub'..."
  fi
done
