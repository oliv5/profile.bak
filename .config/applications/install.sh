#!/bin/sh
SRCPATH="${1:-$PWD}"
for FILE in "${SRCPATH}"/*.desktop; do
    ln -sv "${FILE}" "${HOME}/.local/share/applications/$(basename "${FILE}")"
done
