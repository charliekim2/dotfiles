#!/usr/bin/env bash
# Stop hook -- runs at every turn boundary and checks how full the context
# window is.  Past CTX_THRESHOLD it blocks the stop once and hands Claude
# instructions to stabilise the work and offer a handoff.
#
# A turn boundary is the right place for this: nothing is half-written there.
#
# Fires at most once per session.  The `alerted` flag, written in the same pass
# that emits the block, is what guarantees that -- the alert can never become a
# loop the user has to fight their way out of.
set -uo pipefail
. "$(dirname "$0")/ctx-lib.sh"

input=$(cat)
SID=$(ctx_sid "$(printf '%s' "$input" | jq -r '.session_id // ""')")

USAGE=$CTX_USAGE/$SID
[ -r "$USAGE" ] || exit 0                                  # status line hasn't run
[ "$(ctx_age "$USAGE")" -le "$CTX_USAGE_MAX_AGE" ] || exit 0   # reading is stale

PCT=$(ctx_read "$USAGE" pct 0)
TOKENS=$(ctx_read "$USAGE" tokens 0)
WINDOW=$(ctx_read "$USAGE" window 0)

OVER=""
if [ "$PCT" -ge "$CTX_THRESHOLD" ]; then
  OVER="${PCT}% of the context window is used (threshold ${CTX_THRESHOLD}%)"
elif [ "$CTX_MAX_TOKENS" -gt 0 ] && [ "$TOKENS" -ge "$CTX_MAX_TOKENS" ]; then
  OVER="$TOKENS tokens of context are in use (cap $CTX_MAX_TOKENS)"
fi
[ -n "$OVER" ] || exit 0

SF=$CTX_SESSIONS/$SID
[ "$(ctx_read "$SF" alerted 0)" -eq 0 ] || exit 0
ctx_write "$SF" alerted=1 "pct=$PCT" "tokens=$TOKENS"

REASON="Context budget reached: $OVER, with $TOKENS of $WINDOW tokens in use.

This is a measurement of the window, not a judgement about your output -- but retrieval and instruction-following degrade well before a window is full, and you are past the point where this session is the best place to keep working. You are being stopped here because a turn boundary is the only place where stopping is free.

Do not start new work. Do this, in order:

1. Leave the tree coherent. If something is half-done -- a file mid-edit, a partial rename, a migration written but not wired up -- finish that smallest unit or revert it. Do not expand scope to \"round things out\".

2. Ask the user how to proceed, using AskUserQuestion, with these two options:
   - \"Write handoff and clear\" (recommended) -- you invoke the handoff skill, which writes .claude/HANDOFF.md and arms it; the user then presses /clear and the fresh session continues from it automatically.
   - \"Keep going\" -- you will not be stopped again this session, and the user accepts working in a context this full.

3. Do exactly what they pick, and nothing more. If they choose the handoff, invoke the handoff skill, then tell them to press /clear.

State the numbers plainly in that message so the user can judge for themselves: $TOKENS of $WINDOW tokens, ${PCT}%."

jq -n --arg r "$REASON" --arg m "context at ${PCT}% ($TOKENS/$WINDOW tokens) -- stopping to offer a handoff" \
  '{hookSpecificOutput:{hookEventName:"Stop",decision:"block",reason:$r,systemMessage:("◆ " + $m)}}'
