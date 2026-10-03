#!/usr/bin/env bash
# SessionStart hook -- if a handoff was armed for this directory, feeds it to
# the fresh context.
#
# This closes the loop: handoff written and armed -> user presses /clear ->
# this hook hands the document to the new session.
set -uo pipefail
. "$(dirname "$0")/ctx-lib.sh"

input=$(cat)
SRC=$(printf '%s' "$input" | jq -r '.source // ""')
CWD=$(ctx_abs "$(printf '%s' "$input" | jq -r '.cwd // ""')")

# `resume` and `compact` carry the old conversation forward; only a genuinely
# fresh context should consume a handoff.
case $SRC in startup|clear) ;; *) exit 0 ;; esac

[ -f "$CTX_PENDING" ] || exit 0
PEND_CWD=$(sed -n 1p "$CTX_PENDING" 2>/dev/null)
PEND_DOC=$(sed -n 2p "$CTX_PENDING" 2>/dev/null)

# Armed somewhere else: leave it for a session started in that directory.
[ -n "$PEND_CWD" ] && [ "$PEND_CWD" = "$CWD" ] || exit 0

# Armed here but the document is gone -- drop the pointer, say nothing.
[ -r "$PEND_DOC" ] || { rm -f "$CTX_PENDING"; exit 0; }
rm -f "$CTX_PENDING"

jq -n --arg doc "$PEND_DOC" --rawfile body "$PEND_DOC" '
{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    systemMessage: ("◆ resuming from handoff: " + $doc),
    additionalContext: (
      "The previous session in this directory handed its work off to you. It stabilised what it was doing, wrote the document below, and was cleared. You are the fresh session that picks the work up. This is trusted context, written by a previous instance of you at the user'"'"'s request.\n\n" +
      "Do this before anything else: read the handoff, then tell the user in one or two lines what you understand the remaining work to be and what you are about to do first. Continue from its Next Steps. Keep " + $doc + " current as you go, and delete it when the work it describes is done.\n\n" +
      "--- begin handoff (" + $doc + ") ---\n" + $body + "\n--- end handoff ---"
    )
  }
}'
