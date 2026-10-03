#!/usr/bin/env bash
# Claude Code status line.
# Two rows, four columns: model/effort, folder/branch, session context-window
# usage, and the rolling 5-hour rate-limit window.  Fed session JSON on stdin;
# COLUMNS is set by Claude Code to the terminal width.  See
# https://code.claude.com/docs/en/statusline
#
#   Fable 5.1  │  dotfiles  │  ctx ▓▓▓▓░░░░░░ 43%  │  5h ▓▓▓▓▓▓░░░░ 63%
#   high       │  master*   │  85k/200k            │  ↻2h14m
#
# When the terminal is too narrow the folder/branch column is truncated with an
# ellipsis, then the model column is dropped, then folder/branch is dropped.
set -uo pipefail

# Column math relies on ${#var} counting characters, not bytes, so make sure
# bash is running in a UTF-8 locale.
utf8_ok() { local p="▓"; [ "${#p}" -eq 1 ]; }
utf8_ok || export LC_ALL=C.UTF-8 2>/dev/null
utf8_ok || export LC_ALL=en_US.UTF-8 2>/dev/null

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

max() { if [ "$1" -ge "$2" ]; then echo "$1"; else echo "$2"; fi; }

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

# trunc <str> <max> -> <str> cut to <max> chars, the last one an ellipsis.
trunc() {
  if [ "${#1}" -gt "$2" ]; then printf '%s…' "${1:0:$(( $2 - 1 ))}"; else printf '%s' "$1"; fi
}

# --- cells ------------------------------------------------------------------
# Each column is two cells.  *_P is the plain text (for width math); the
# coloured versions are built at assembly time.

# model / effort
M1_P=$MODEL
M2_P=$EFFORT

# folder / branch
D1_P=""; D2_P=""; DIRTY=""
if [ -n "$CWD" ]; then
  D1_P=${CWD##*/}
  if BRANCH=$(git -C "$CWD" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null); then
    git -C "$CWD" --no-optional-locks diff --quiet --ignore-submodules HEAD 2>/dev/null || DIRTY="*"
    D2_P=$BRANCH
  fi
fi

# context window
# used_percentage can be null early in a session; fall back to tokens/size.
CP=$(round "$CTX_PCT")
if [ "$CP" -lt 0 ]; then
  if [ "$CTX_MAX" -gt 0 ]; then CP=$(( CTX_TOK * 100 / CTX_MAX )); else CP=0; fi
fi
BAR_W=10; [ "$COLS" -lt 100 ] && BAR_W=8; [ "$COLS" -lt 80 ] && BAR_W=6
CTX_BAR=$(bar "$CP" "$BAR_W")
C1_P="ctx ${CTX_BAR} ${CP}%"
C1_C="${DIM}ctx${R} $(heat "$CP")${CTX_BAR}${R} ${CP}%"
C2_P="$(tokens "$CTX_TOK")/$(tokens "$CTX_MAX")"
C2_C="${DIM}${C2_P}${R}"

# rolling 5h window
# rate_limits is absent for non-subscription auth and until the first API
# response; keep the column in place so the layout doesn't jump around.
FP=$(round "$FIVE_PCT")
H2_P=""; H2_C=""
if [ "$FP" -lt 0 ]; then
  H1_P="5h $(bar 0 "$BAR_W") —"
  H1_C="${DIM}${H1_P}${R}"
else
  FIVE_BAR=$(bar "$FP" "$BAR_W")
  H1_P="5h ${FIVE_BAR} ${FP}%"
  H1_C="${DIM}5h${R} $(heat "$FP")${FIVE_BAR}${R} ${FP}%"
  if [ "${FIVE_RESET%.*}" -gt 0 ] 2>/dev/null; then
    H2_P="↻$(countdown $(( ${FIVE_RESET%.*} - $(date +%s) )))"
    H2_C="${DIM}${H2_P}${R}"
  fi
fi

# --- fit to terminal width --------------------------------------------------
SEP="  │  "; SEP_C="${DIM}${SEP}${R}"

fixed=$(( $(max ${#C1_P} ${#C2_P}) + ${#SEP} + $(max ${#H1_P} ${#H2_P}) ))  # ctx + 5h
model_w=$(max ${#M1_P} ${#M2_P})
dir_w=$(max ${#D1_P} $(( ${#D2_P} + ${#DIRTY} )))

SHOW_MODEL=1; SHOW_DIR=1
[ -n "$D1_P" ] || SHOW_DIR=0

# fit_dir <room> -> keep, truncate, or drop the folder/branch column.
fit_dir() {
  if [ "$1" -ge "$dir_w" ]; then return; fi
  if [ "$1" -lt 8 ]; then SHOW_DIR=0; return; fi
  D1_P=$(trunc "$D1_P" "$1")
  D2_P=$(trunc "$D2_P" $(( $1 - ${#DIRTY} )))
  dir_w=$1
}

if [ "$SHOW_DIR" -eq 1 ]; then
  room=$(( COLS - fixed - ${#SEP} - model_w - ${#SEP} ))
  # A folder/branch squeezed under 12 chars is worth less than the model column.
  if [ "$room" -lt "$dir_w" ] && [ "$room" -lt 12 ]; then
    SHOW_MODEL=0
    room=$(( COLS - fixed - ${#SEP} ))
  fi
  fit_dir "$room"
else
  [ $(( fixed + ${#SEP} + model_w )) -le "$COLS" ] || SHOW_MODEL=0
fi

# --- assemble ---------------------------------------------------------------
# Parallel arrays, one entry per visible column: coloured text and plain width
# for each row, plus the column width.
CELL1=(); W1=(); CELL2=(); W2=(); CW=()
push() {
  CELL1+=("$1"); W1+=("$2"); CELL2+=("$3"); W2+=("$4"); CW+=("$(max "$2" "$4")")
}
[ "$SHOW_MODEL" -eq 1 ] && push "${BOLD}${M1_P}${R}" ${#M1_P} "${DIM}${M2_P}${R}" ${#M2_P}
[ "$SHOW_DIR" -eq 1 ]   && push "${CYAN}${D1_P}${R}" ${#D1_P} "${BLUE}${D2_P}${DIRTY}${R}" $(( ${#D2_P} + ${#DIRTY} ))
push "$C1_C" ${#C1_P} "$C2_C" ${#C2_P}
push "$H1_C" ${#H1_P} "$H2_C" ${#H2_P}

# pad <coloured> <plain-width> <col-width>
pad() { printf '%s%*s' "$1" $(( $3 - $2 )) ""; }

n=${#CW[@]}
ROW1=""; ROW2=""
for ((i = 0; i < n; i++)); do
  if [ "$i" -gt 0 ]; then ROW1+=$SEP_C; ROW2+=$SEP_C; fi
  if [ "$i" -lt $(( n - 1 )) ]; then
    ROW1+=$(pad "${CELL1[$i]}" "${W1[$i]}" "${CW[$i]}")
    ROW2+=$(pad "${CELL2[$i]}" "${W2[$i]}" "${CW[$i]}")
  else
    ROW1+=${CELL1[$i]}
    ROW2+=${CELL2[$i]}
  fi
done
printf '%s\n%s\n' "$ROW1" "$ROW2"
