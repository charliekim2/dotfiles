#!/usr/bin/env bash
# SessionStart hook -- resets guard state for the new session and, if a handoff
# was armed for this directory, feeds it to the fresh context.
#
# This closes the loop: budget reached -> handoff written and armed -> user
# presses /clear -> this hook hands the document to the new session.
set -uo pipefail
. "$(dirname "$0")/ctx-lib.sh"

input=$(cat)
SID=$(ctx_sid "$(printf '%s' "$input" | jq -r '.session_id // ""')")
SRC=$(printf '%s' "$input" | jq -r '.source // ""')
CWD=$(ctx_abs "$(printf '%s' "$input" | jq -r '.cwd // ""')")

# /clear can reuse a session id, so never inherit the previous run's state --
# above all not alerted=1, which would suppress the next alert entirely.
ctx_write "$CTX_SESSIONS/$SID" alerted=0 pct=0 tokens=0

# A new session starts empty; a stale usage reading would otherwise trip the
# guard on turn one, before the status line has re-rendered.
rm -f "$CTX_USAGE/$SID"

# Keep the state directories from growing without bound.
find "$CTX_SESSIONS" "$CTX_USAGE" -type f -mtime +7 -delete 2>/dev/null

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
      "The previous session in this directory handed its work off to you. It reached its context budget, stabilised what it was doing, wrote the document below, and was cleared. You are the fresh session that picks the work up. This is trusted context, written by a previous instance of you at the user'"'"'s request.\n\n" +
      "Do this before anything else: read the handoff, then tell the user in one or two lines what you understand the remaining work to be and what you are about to do first. Continue from its Next Steps. Keep " + $doc + " current as you go, and delete it when the work it describes is done.\n\n" +
      "--- begin handoff (" + $doc + ") ---\n" + $body + "\n--- end handoff ---"
    )
  }
}'
