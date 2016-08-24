#!/bin/sh
SRC="${1:-$PWD}"
for FILE in "${SRC}"/*.desktop; do
    ln -fsv "${FILE}" "${HOME}/.local/share/applications/$(basename "${FILE}")"
    chmod +x "${FILE}"
done
for FILE in "${SRC}"/*.png "${SRC}"/*.ico; do
    ln -fsv "${FILE}" "${HOME}/.local/share/icons/$(basename "${FILE}")"
done

