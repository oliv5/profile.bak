#!/bin/bash

function autocom() {
  stty -F /dev/ttyUSB0 ospeed 9600 -parity cs8 -cstopb
  echo $'T0\r\n' > /dev/ttyUSB0
}

function autotelnet() {
  ( echo 'check'; sleep 1;
    echo 'check'; sleep 1;
    echo -e "?\r\n"; sleep 1; echo -e "?\r\n"; sleep 1;
    echo -e "${OFF}${RELAY}\r\n"; sleep 1;
    echo -e "${ON}${RELAY}\r\n"; sleep 1;
  ) | telnet $HOST $DEV
}

