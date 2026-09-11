#!/usr/bin/env bash
# Shared helpers for the context guard.  Sourced, never run directly.
#
# The guard watches how full the context window is and, past a threshold, stops
# the session at a turn boundary to offer a handoff.  It is deliberately a
# measurement of the window rather than of the model's behaviour: a model far
# enough gone to need a handoff is exactly the wrong thing to ask.
#
# bash 3.2 compatible -- macOS ships nothing newer.

CTX_GUARD_HOME=${CTX_GUARD_HOME:-$HOME/.claude/ctx-guard}
CTX_USAGE=$CTX_GUARD_HOME/usage          # written by statusline.sh, per session
CTX_SESSIONS=$CTX_GUARD_HOME/sessions    # our own per-session state
CTX_PENDING=$CTX_GUARD_HOME/pending-handoff

# Percentage of the context window at which to offer a handoff.
CTX_THRESHOLD=${CTX_THRESHOLD:-60}

# Optional absolute cap, in tokens; 0 disables it.  Worth setting on a 1M
# window, where 60% is 600k tokens and retrieval has degraded long before.
CTX_MAX_TOKENS=${CTX_MAX_TOKENS:-0}

# The status line writes usage every time it renders.  If it has not run -- no
# status line configured, or it failed -- the guard stays quiet rather than
# guessing.  Stale readings are ignored for the same reason.
CTX_USAGE_MAX_AGE=${CTX_USAGE_MAX_AGE:-3600}

ctx_sid() {
  local sid
  sid=$(printf '%s' "${1:-}" | tr -cd 'A-Za-z0-9_-')
  [ -n "$sid" ] || sid=unknown
  printf '%s' "$sid"
}

# ctx_read <file> <key> <default> -- every value we store is an integer, so
# anything else (missing file, truncated write) falls back to the default.
ctx_read() {
  local v
  v=$(sed -n "s/^$2=//p" "$1" 2>/dev/null | tail -1)
  case $v in ''|*[!0-9]*) printf '%s' "$3" ;; *) printf '%s' "$v" ;; esac
}

# ctx_write <file> <key=value>... -- whole-file rewrite via a temp file, so a
# killed hook can never leave half a state behind.
ctx_write() {
  local f=$1 kv
  shift
  mkdir -p "${f%/*}" || return 1
  : > "$f.$$" || return 1
  for kv in "$@"; do printf '%s\n' "$kv" >> "$f.$$"; done
  mv -f "$f.$$" "$f"
}

# Seconds since a file was last modified, or a very large number if unknown --
# an unreadable mtime should read as stale, never as fresh.
ctx_age() {
  local m now
  now=$(date +%s)
  m=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null) || { printf '999999999'; return; }
  case $m in ''|*[!0-9]*) printf '999999999' ;; *) printf '%s' $(( now - m )) ;; esac
}

# Physical absolute path, so a cwd from a hook payload and one from a shell
# compare equal despite symlinks or a trailing slash.
ctx_abs() {
  local r
  r=$(cd "$1" 2>/dev/null && pwd -P) || { printf '%s' "$1"; return; }
  printf '%s' "$r"
}
