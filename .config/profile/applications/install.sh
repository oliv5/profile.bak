#!/bin/sh
SRCPATH="${1:-$PWD}"
for FILE in "${SRCPATH}"/*.desktop; do
    ln -fsv "${FILE}" "${HOME}/.local/share/applications/$(basename "${FILE}")"
done
