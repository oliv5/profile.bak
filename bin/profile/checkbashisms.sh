#!/bin/sh
find "${1:-.}" -name "${2:-*.sh}" -exec sh -c 'checkbashisms {} 2>/dev/null || echo "checkbashisms {}"' \;
