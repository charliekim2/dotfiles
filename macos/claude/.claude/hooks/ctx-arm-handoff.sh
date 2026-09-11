#!/usr/bin/env bash
# Arm a handoff document so the next fresh session started in this directory
# reads it automatically.  Invoked by the `handoff` skill once it has written
# the document; safe to run by hand.
#
#   ctx-arm-handoff.sh <path-to-handoff.md> [directory]
#
# The pointer is one-shot: ctx-session-start.sh consumes it and deletes it.
# The document itself stays on disk.
set -uo pipefail
. "$(dirname "$0")/ctx-lib.sh"

DOC=${1:-}
[ -n "$DOC" ] || { echo "usage: ${0##*/} <path-to-handoff.md> [directory]" >&2; exit 64; }
[ -r "$DOC" ] || { echo "${0##*/}: no readable handoff document at $DOC" >&2; exit 66; }

case $DOC in /*) ;; *) DOC=$PWD/$DOC ;; esac
DIR=$(ctx_abs "${2:-$PWD}")

mkdir -p "$CTX_GUARD_HOME"
printf '%s\n%s\n' "$DIR" "$DOC" > "$CTX_PENDING"

echo "armed: $DOC"
echo "the next session started in $DIR will pick it up -- press /clear"
