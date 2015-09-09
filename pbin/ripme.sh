#!/bin/bash
# Note: need to fix the \" errors around filenames

# Ensure an almost clean exit
# Enable errors before
ExitHandler() {
  set +e
  # Clean up device information file
  rm "$DEVINFO" 2>/dev/null
  # Release mutex & exit
  rm "$PIDFILE" 2>/dev/null
  # Kill running binaries
  killall -v -9 $BINARIES 2>/dev/null
  killall -v -9 ${@:2} 2>/dev/null
  # The end
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
VERSION=1.20
TYPE="auto"
DEVICE=""
TRACKS="longest"
ODIR="."
ADIR=""
TITLE=""
DRYRUN=""
SLANGS=""
ALANGS="en"
SPEED="2"
RENAME=""
OVERWRITE=""
INSTALL=""
METHOD="mplayer"
PKGINSTALL="apt-get install"
PKGREPO="add-apt-repository"
PKGUPDATE="apt-get update"
DEVINFO="/tmp/$(basename $0).$(date +%s).tmp"
SPEED_DVD=(1 2 4 8 12 16)
SPEED_CD=(4 8 24 32 40 48)
BINARIES="tccat mplayer mencoder vlc subtitleripper vobsub2srt cdparanoia oggenc"

# Get command line options
while getopts :t:d:e:m:o:u:f:c:s:a:rwnik OPTNAME
do case "$OPTNAME" in
  t)  TYPE="$OPTARG";;
  d)  DEVICE="$OPTARG";;
  e)  SPEED="$(($OPTARG - 1))";;
  m)  METHOD="$OPTARG";;
  o)  ODIR="$OPTARG";;
  u)  ADIR="$OPTARG";;
  f)  TITLE="$OPTARG";;
  c)  TRACKS="$OPTARG";;
  s)  SLANGS="$OPTARG";;
  a)  ALANGS="$OPTARG";;
  r)  RENAME="1"; OVERWRITE="";;
  w)  OVERWRITE="1"; RENAME="";;
  n)  DRYRUN="echo";;
  i)  INSTALL=1;;
  k)  ExitHandler 0 ripme;;
  [?]) echo >&2 "Ripme $VERSION - rips dvd, audio cd, extracts subtitles"
       echo >&2 "Usage: $(basename $0) [options]"
       echo >&2 "-t type    Media type: auto, dvd, cdda (auto)"
       echo >&2 "-d device  Device name in /dev (/dev/dvd)"
       echo >&2 "-e speed   Device read speed : 1,2,... (2)"
       echo >&2 "-m method  Ripping method: tccat, mplayer, vlc (mplayer)"
       echo >&2 "-o dir     Output directory (current)"
       echo >&2 "-u dir     Audio output directory override (none)"
       echo >&2 "-f file    Output filename (media title)"
       echo >&2 "-c tracks  Track numbers: all,disc,longest,0,1,2,... (longest)"
       echo >&2 "-s langs   DVD subtitles languages: en,fr,es,... (none)"
       echo >&2 "-a langs   DVD audio languages: en,fr,es,... (en) - only with vlc"
       echo >&2 "-r         Rename existing output file (disabled). Exclusive with -w"
       echo >&2 "-w         Allow output file overwrite (disabled). Exclusive with -r"
       echo >&2 "-n         No dump, simulate only"
       echo >&2 "-i         Install necessary software"
       exit 1;;
  esac
done
shift $(expr $OPTIND - 1)
unset OPTNAME OPTARG

# Mutex exclusion
PIDFILE="/tmp/ripme.pid"
exec 200>"$PIDFILE" || exit 1
flock -n 200 || exit 1
echo $$ 1>&200

# Log preamble
echo >&2 "Start at $(date)"
touch "$DEVINFO"

# Install necessary software
if [ ! -z "$INSTALL" ]; then
  $DRYRUN sudo $PKGINSTALL ppa:ruediger-c-plusplus/vobsub2srt
  $DRYRUN sudo $PKGUPDATE
  $DRYRUN sudo $PACKAGEMANAGER vlc
  $DRYRUN sudo $PACKAGEMANAGER mplayer
  $DRYRUN sudo $PACKAGEMANAGER hdparm
  $DRYRUN sudo $PACKAGEMANAGER transcode subtitleripper
  $DRYRUN sudo $PACKAGEMANAGER vobsub2srt libavutil-dev libtiff4-dev libtesseract-dev tesseract-ocr-eng tesseract-ocr-fra
  #$DRYRUN sudo $PACKAGEMANAGER build-essential pkg-config cmake checkinstall
  $DRYRUN sudo $PACKAGEMANAGER qpxtool hdparm
fi

# Read DVD information
if [ "$TYPE" = "auto" -o "$TYPE" = "dvd" ]; then
  DEVICE="${DEVICE:-/dev/dvd}"
  lsdvd -x "$DEVICE" > "$DEVINFO" 2>/dev/null
  if [ $? -eq 0 ]; then
    TYPE="dvd"
    echo >&2 "Detected DVD media in device '$DEVICE'"
  elif [ "$TYPE" = "dvd" ]; then
    echo >&2 "Error: cannot read DVD information from device '$DEVICE'..."
    ExitHandler 1
  fi
fi

# Read audio CD information
if [ "$TYPE" = "auto" -o "$TYPE" = "cdda" ]; then
  DEVICE="${DEVICE:-/dev/cdrom}"
  cdrecord dev="$DEVICE" -toc > "$DEVINFO" 2>/dev/null
  if [ $? -eq 0 ]; then
    TYPE="cdda"
    echo >&2 "Detected audio CD media in device '$DEVICE'"
  elif [ "$TYPE" = "cdda" ]; then
    echo >&2 "Error: cannot read audio CD information from device '$DEVICE'..."
    ExitHandler 1
  fi
  # Get audio output directory
  if [ ! -z "$ADIR" ]; then
    ODIR="$ADIR"
  fi
fi

# Check device presence. Failure if not detected
if [ ! -z "$DEVICE" -a ! -e "$DEVICE" ]; then
  echo >&2 "Error: device '$DEVICE' is unknown..."
  ExitHandler 1
fi

# Create output directory. Failure when not existent
echo >&1 "Using output directory '$ODIR'"
mkdir -p "$ODIR"
if [ ! -d "$ODIR" ]; then
  echo >&2 "Error: directory '$ODIR' cannot be created..."
  ExitHandler 1
fi

# Main processing
if [ "$TYPE" = "dvd" ]; then

  # Set device speed
  if [ ! -z "$SPEED" ]; then
    # see http://hektor.umcs.lublin.pl/~mikosmul/computing/tips/cd-rom-speed.html
    # see http://manpages.ubuntu.com/manpages/precise/man1/cdvdcontrol.1.html
    SPEED=${SPEED_DVD[$SPEED]}
    if [ "$METHOD" = "mplayer" ]; then
      SPEED="-dvd-speed $SPEED"
    else
      sudo cdvdcontrol -d "$DEVICE" -s --silent on --sm-dvd-rd $SPEED --sm-nosave || \
      sudo hdparm -E $SPEED "$DEVICE" || \
      sudo eject -x $SPEED "$DEVICE"
    fi
  fi

  # Extract DVD title
  if [ -z "$TITLE" ]; then
    TITLE=$(awk '/Disc Title/ {print $3}' "$DEVINFO")
    if [ -z "$TITLE" ]; then
      echo >&2 "Error: cannot get DVD title..."
      ExitHandler 1
    fi
  fi

  # Select DVD tracks
  MAINTRACK=$(awk '/Longest track:/ {print $3}' "$DEVINFO")
  if [ -z "$MAINTRACK" ]; then
    echo >&2 "Error: cannot get DVD tracks..."
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
      echo >&2 "Dump: skip existing vob file '$DUMPFILE'..."
      continue
    fi

    # Choose the dump method: tccat, vlc, mplayer
    if [ "$METHOD" = "mplayer" ]; then

      # Proceed with the dump
      $DRYRUN mplayer dvd://${TRACK} ${DEVICE:+-dvd-device "$DEVICE"} -dumpstream -dumpfile "$DUMPFILE" ${SPEED}

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
        $DRYRUN rm "$TMP.idx" "$TMP.sub"
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
                echo >&2 "Warning: cannot find subtitle '$LANG'..."
              fi
            else
              echo >&2 "Dump: skip existing subtitle file '$SUBFILESUB'..."
            fi
          done
      else
        echo >&2 "Warning: couldn't retrieve subtitle palette, cancel subtitle extraction..."
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

    # Set output files/directory ownership
    if [ ! -z "$DUMPFILE" ]; then
      $DRYRUN chown --reference="${ODIR}" "$ODIR" "$DUMPFILE"
    fi

  done

elif [ "$TYPE" = "cdda" ]; then

  # Set device speed
  if [ ! -z "$SPEED" ]; then
    # see http://hektor.umcs.lublin.pl/~mikosmul/computing/tips/cd-rom-speed.html
    # see http://manpages.ubuntu.com/manpages/precise/man1/cdvdcontrol.1.html
    SPEED=${SPEED_CD[$SPEED]}
    #sudo cdvdcontrol -d "$DEVICE" -s --silent on --sm-cd-rd $SPEED --sm-nosave || \
    sudo hdparm -E $SPEED "$DEVICE" || \
    sudo eject -x $SPEED "$DEVICE"
  fi

  # Extract audio CD tracks
  FIRST=$(awk '/first:/ {print $2}' "$DEVINFO")
  LAST=$(awk '/last/ {print $4}' "$DEVINFO")
  LENGTH=$(awk "/track: +${LAST}/ {print "'$7}' "$DEVINFO")
  if [ -z "$FIRST" -o -z "$LAST" -o -z "$LENGTH" ]; then
    echo >&2 "Error: cannot get audio CD tracks..."
    ExitHandler 1
  fi

  # Select audio CD tracks
  if expr "$TRACKS" : '-\?[0-9]\+$' >/dev/null; then
    FIRST="$TRACKS"
    LAST="$TRACKS"
  fi

  # Create output directory
  ODIR="$(echo "${ODIR}/${TITLE:-AudioCD}_${LENGTH}" | tr ':' '_')"
  mkdir -p "$ODIR"
  if [ ! -d "$ODIR" ]; then
    echo >&2 "Error: directory '$ODIR' cannot be created..."
    ExitHandler 1
  fi

  # Set the trap signal
  trap "ExitHandler 2" 2

  # Rip it
  for TRACK in $(seq $FIRST $LAST); do
    # Build track filename
    DUMPFILE="${ODIR}/track${TRACK}.ogg"
    TMPFILE="/tmp/track${TRACK}.ogg.wav"

    # Check the output file name
    if ! CheckOutputFilename "DUMPFILE"; then
      echo >&2 "Dump: skip existing vob file '$DUMPFILE'..."
      continue
    fi

    # Ripnow
    #$DRYRUN mplayer cdda://${TRACK} ${DEVICE:+-cdrom-device "$DEVICE"} -nocache -dumpstream -dumpfile "$TMPFILE"
    $DRYRUN cdparanoia ${TRACK} -d "${DEVICE}" "${TMPFILE}"
    #$DRYRUN sh -c "oggenc -q 7 \"${TMPFILE}\" -o \"${DUMPFILE}\" ; rm \"${TMPFILE}\"" &
    $DRYRUN sh -c "oggenc -q 7 \"${TMPFILE}\" -o \"${DUMPFILE}\"" &
  done

  # Set output files/directory ownership
  $DRYRUN chown -R --reference="${ODIR}" "$ODIR"

elif [ "$TYPE" = "auto" ]; then

  echo >&2 "Error: cannot identify media type..."
  ExitHandler 1

else
  echo >&2 "Error: device type '$TYPE' is not supported..."
fi

# Log conclusion
echo >&2 "End at $(date)"

# Exit
ExitHandler 0

----------------------------------------------

    # Dump vob file
    if [ ! -e "$DUMPFILE" -o ! -z "$OVERWRITE" ]; then
      $DRYRUN mplayer dvd://${TRACK} ${DEVICE:+-dvd-device "$DEVICE"} -dumpstream -dumpfile "$DUMPFILE"
    else
      echo >&2 "Dump: skip existing vob file '$DUMPFILE'..."
    fi
    # Dump subtitles
    for LANG in ${SLANGS//,/ }; do
      SUBFILE="${DUMPFILE%.*}_${LANG}"
      if [ ! -e "$SUBFILE.sub" -o ! -z "$OVERWRITE" ]; then
        SUBINDEX=$(awk -F ' |,' '/Subtitle:.*Language: '$LANG'/ {print $14}' "$DEVINFO" | head -n 1)
        if [ ! -z "$SUBINDEX" ]; then
          $DRYRUN rm "$SUBFILE.*" 2>/dev/null
          $DRYRUN mencoder dvd://${TRACK} ${DEVICE:+-dvd-device "$DEVICE"} -nosound -ovc frameno -sid $SUBINDEX -vobsubout "$SUBFILE" -vobsuboutid $LANG -o /dev/null 2>/dev/null
          if [ -s "$SUBFILE.sub" ]; then
            echo >&2 "Dump: failed to extract subtitles, try alternative method..."
            $DRYRUN sh -c "tccat -i \"$DEVICE\" -T ${TRACK},-1 | tcextract -x ps1 -t vob -a $SUBINDEX > \"$SUBFILE.tmp\""
            $DRYRUN subtitle2vobsub -p "$SUBFILE.tmp" -o "$SUBFILE"
            $DRYRUN rm "$SUBFILE.tmp"
          fi
          $DRYRUN sh -c " \
            vobsub2srt --lang $LANG \"$SUBFILE\" ; \
            sed -ri -e 's/\|/l/g' -e 's/ l$/ ?/' -e 's/\.7$/?/' -e 's/^([^0-9].*)7$/\1 ?/' \"$SUBFILE.srt\" ; \
            " &
        else
          echo >&2 "Warning: cannot find subtitle '$LANG'..."
        fi
      else
        echo >&2 "Dump: skip existing subtitle file '$SUBFILE.sub'..."
      fi
    done

