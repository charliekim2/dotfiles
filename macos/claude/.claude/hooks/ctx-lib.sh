#!/usr/bin/env bash
# Shared helpers for handoffs.  Sourced, never run directly.
#
# The handoff skill writes a document and arms it with ctx-arm-handoff.sh;
# ctx-session-start.sh feeds it to the next fresh session in that directory.
#
# bash 3.2 compatible -- macOS ships nothing newer.

CTX_GUARD_HOME=${CTX_GUARD_HOME:-$HOME/.claude/ctx-guard}
CTX_PENDING=$CTX_GUARD_HOME/pending-handoff

# Physical absolute path, so a cwd from a hook payload and one from a shell
# compare equal despite symlinks or a trailing slash.
ctx_abs() {
  local r
  r=$(cd "$1" 2>/dev/null && pwd -P) || { printf '%s' "$1"; return; }
  printf '%s' "$r"
}
