#!/bin/sh
# Recalbox - Watch RetroArch retroarch.log for RetroAchievements unlocks and call Pixelcade script.

LOGDIR="/recalbox/share/system/.config/retroarch/logs"
RETROARCH_LOG="$LOGDIR/retroarch.log"

# OUTLOG="/recalbox/share/userscripts/rcheevos_watcher.log"
OUTLOG="/dev/null"
PIDFILE="/tmp/rcheevos_watcher.pid"
LASTID="/tmp/rcheevos_last_id"

CALL_SCRIPT="/recalbox/share/bootvideos/pixelcade/pixelcade_achievements.sh"

ACTION=""
STATEFILE=""
PARAMPATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    -action) ACTION="$2"; shift 2 ;;
    -statefile) STATEFILE="$2"; shift 2 ;;
    -param) PARAMPATH="$2"; shift 2 ;;
    *) shift ;;
  esac
done

log() { echo "$(date '+%F %T') $*" >> "$OUTLOG"; }

ini_get() {
  key="$1"
  [ -f "$STATEFILE" ] || return 0
  grep -m1 "^${key}=" "$STATEFILE" | cut -d= -f2- | tr -d '\r'
}

compute_romname() {
  rompath="${1%/}"
  [ -z "$rompath" ] && { echo ""; return 0; }

  romname="$(basename "$rompath")"

  # Strip extension only if it's a file
  if [ -f "$rompath" ]; then
    romname="${romname%.*}"
  fi

  # If .cue => prefer the parent folder name
  case "$rompath" in
    *.cue) romname="$(basename "$(dirname "$rompath")")" ;;
  esac

  echo "$romname"
}

stop_watcher() {
  if [ -f "$PIDFILE" ]; then
    pid="$(cat "$PIDFILE" 2>/dev/null)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      # Kill children (tail) then parent
      if command -v pkill >/dev/null 2>&1; then
        pkill -P "$pid" 2>/dev/null
      fi
      kill "$pid" 2>/dev/null
      log "STOP pid=$pid"
    fi
    rm -f "$PIDFILE"
  fi
}

start_watcher() {
  stop_watcher

  mkdir -p /recalbox/share/userscripts 2>/dev/null
  mkdir -p "$LOGDIR" 2>/dev/null
  touch "$RETROARCH_LOG" 2>/dev/null

  SYSTEMID="$(ini_get SystemId)"
  GAME="$(ini_get Game)"
  GAMEPATH="$(ini_get GamePath)"

  ROMPATH="${PARAMPATH%/}"
  [ -z "$ROMPATH" ] && ROMPATH="${GAMEPATH%/}"

  ROMNAME="$(compute_romname "$ROMPATH")"
  [ -z "$ROMNAME" ] && ROMNAME="$GAME"

  log "START action=$ACTION system=$SYSTEMID game=$GAME romname=$ROMNAME log=$RETROARCH_LOG call=$CALL_SCRIPT"

  (
    # Low priority so it never impacts emulation
    nice -n 10 tail -n 0 -F "$RETROARCH_LOG" 2>>"$OUTLOG" \
    | while IFS= read -r line; do
        # Fast filter: ignore almost everything
        case "$line" in
          *"[RCHEEVOS]:"*"Awarding achievement "*)
            # Example:
            # [INFO] [RCHEEVOS]: Awarding achievement 302975: Single Pringle
            rest="${line#*Awarding achievement }"  # "302975: Single Pringle"
            id="${rest%%:*}"                       # "302975"
            title="${rest#*: }"                    # "Single Pringle"
            [ -z "$id" ] && continue

            # Dedup (sometimes the same line can appear twice)
            last="$(cat "$LASTID" 2>/dev/null)"
            [ "$id" = "$last" ] && continue
            echo "$id" > "$LASTID"

            log "UNLOCK id=$id title=$title romname=$ROMNAME"

            if [ -f "$CALL_SCRIPT" ]; then
              # Pixelcade expects: $1=id, $2=title, $3=romname
              bash "$CALL_SCRIPT" "$id" "$title" "$ROMNAME" >> "$OUTLOG" 2>&1
              log "CALL exitcode=$?"
            else
              log "ERROR missing CALL_SCRIPT=$CALL_SCRIPT"
            fi
            ;;
        esac
      done
  ) &

  echo $! > "$PIDFILE"
}

case "$ACTION" in
  rungame|rundemo) start_watcher ;;
  endgame|enddemo) stop_watcher ;;
  *) : ;;
esac

exit 0
