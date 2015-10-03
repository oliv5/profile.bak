#!/bin/sh

# Batch bundle repos
repo_bundle() {
  local ARGS="\"$1\" \"$2\" \"$3\""
  shift 3 2>/dev/null
  eval repo forall "\"$@\"" -c git_bundle "$ARGS"
}
