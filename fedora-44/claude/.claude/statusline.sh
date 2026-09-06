#!/usr/bin/env bash
# Claude Code status line.
# Shows model/effort, cwd + git branch, session context-window usage, and the
# rolling 5-hour rate-limit window.  Fed session JSON on stdin; see
# https://code.claude.com/docs/en/statusline
set -uo pipefail

input=$(cat)

R=$'\033[0m'; DIM=$'\033[2m'; BOLD=$'\033[1m'
GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
BLUE=$'\033[34m'; CYAN=$'\033[36m'

# One jq pass, one value per line, so paths with spaces survive.
mapfile -t F < <(printf '%s' "$input" | jq -r '
  (.model.display_name // "?"),
  (.effort.level // ""),
  (.workspace.current_dir // .cwd // ""),
  (.context_window.used_percentage // -1),
  (.context_window.total_input_tokens // 0),
  (.context_window.context_window_size // 200000),
  (.rate_limits.five_hour.used_percentage // -1),
  (.rate_limits.five_hour.resets_at // 0)
')

MODEL=${F[0]:-?}
EFFORT=${F[1]:-}
CWD=${F[2]:-}
CTX_PCT=${F[3]:--1}
CTX_TOK=${F[4]:-0}
CTX_MAX=${F[5]:-200000}
FIVE_PCT=${F[6]:--1}
FIVE_RESET=${F[7]:-0}

COLS=${COLUMNS:-100}

# Round a possibly-fractional percentage to an int, clamped at 0.
round() { printf '%.0f' "${1:-0}" 2>/dev/null || echo 0; }

# Green under 50%, yellow under 80%, red at or above.
heat() {
  local p=$1
  if   [ "$p" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$p" -ge 50 ]; then printf '%s' "$YELLOW"
  else                       printf '%s' "$GREEN"
  fi
}

# bar <pct> <width> -> filled blocks up to <pct>, remainder as light shade.
bar() {
  local pct=$1 width=$2 filled i out=""
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0 ] && pct=0
  filled=$(( (pct * width + 50) / 100 ))
  for ((i = 0; i < width; i++)); do
    if [ "$i" -lt "$filled" ]; then out+="▓"; else out+="░"; fi
  done
  printf '%s' "$out"
}

# 15500 -> 16k, 1000000 -> 1.0M
tokens() {
  local t=${1:-0}
  if   [ "$t" -ge 1000000 ]; then awk -v t="$t" 'BEGIN{printf "%.1fM", t/1000000}'
  elif [ "$t" -ge 1000 ];    then printf '%dk' $(( (t + 500) / 1000 ))
  else                            printf '%d' "$t"
  fi
}

# Seconds until reset -> "2h14m" / "47m" / "<1m"
countdown() {
  local secs=$1 h m
  [ "$secs" -le 0 ] && { printf '<1m'; return; }
  h=$(( secs / 3600 )); m=$(( (secs % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then printf '%dh%02dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then printf '%dm' "$m"
  else printf '<1m'
  fi
}

# --- model + effort ---------------------------------------------------------
SEG_MODEL="${BOLD}${MODEL}${R}"
[ -n "$EFFORT" ] && SEG_MODEL+="${DIM}·${EFFORT}${R}"

# --- cwd + git --------------------------------------------------------------
SEG_DIR=""
if [ -n "$CWD" ]; then
  SEG_DIR="${CYAN}${CWD##*/}${R}"
  if BRANCH=$(git -C "$CWD" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null); then
    DIRTY=""
    git -C "$CWD" --no-optional-locks diff --quiet --ignore-submodules HEAD 2>/dev/null || DIRTY="*"
    SEG_DIR+=" ${BLUE}${BRANCH}${DIRTY}${R}"
  fi
fi

# --- context window ---------------------------------------------------------
# used_percentage can be null early in a session; fall back to tokens/size.
CP=$(round "$CTX_PCT")
if [ "$CP" -lt 0 ]; then
  if [ "$CTX_MAX" -gt 0 ]; then CP=$(( CTX_TOK * 100 / CTX_MAX )); else CP=0; fi
fi
CTX_W=10; [ "$COLS" -lt 100 ] && CTX_W=8; [ "$COLS" -lt 80 ] && CTX_W=6
SEG_CTX="${DIM}ctx${R} $(heat "$CP")$(bar "$CP" "$CTX_W")${R} ${CP}%"
[ "$COLS" -ge 100 ] && SEG_CTX+=" ${DIM}($(tokens "$CTX_TOK")/$(tokens "$CTX_MAX"))${R}"

# --- rolling 5h window ------------------------------------------------------
# rate_limits is absent for non-subscription auth and until the first API
# response; keep the segment in place so the line doesn't jump around.
FP=$(round "$FIVE_PCT")
if [ "$FP" -lt 0 ]; then
  SEG_5H="${DIM}5h $(bar 0 "$CTX_W") —${R}"
else
  SEG_5H="${DIM}5h${R} $(heat "$FP")$(bar "$FP" "$CTX_W")${R} ${FP}%"
  if [ "${FIVE_RESET%.*}" -gt 0 ] 2>/dev/null; then
    SEG_5H+=" ${DIM}↻$(countdown $(( ${FIVE_RESET%.*} - $(date +%s) )))${R}"
  fi
fi

# --- assemble ---------------------------------------------------------------
SEP="${DIM}  │  ${R}"
if [ "$COLS" -lt 70 ]; then
  printf '%s%s%s\n' "$SEG_CTX" "$SEP" "$SEG_5H"
else
  printf '%s%s%s%s%s%s%s\n' "$SEG_MODEL" "$SEP" "$SEG_DIR" "$SEP" "$SEG_CTX" "$SEP" "$SEG_5H"
fi
