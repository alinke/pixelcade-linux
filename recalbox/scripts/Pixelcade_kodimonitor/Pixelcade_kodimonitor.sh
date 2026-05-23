#!/bin/bash
# =====================================================================
# Kodi -> Pixelcade secondary displays monitor
# V8 compact readable version
# - loop synchronized with system clock seconds
# - 7-segment clock is refreshed first
# - LCD/DOT are updated only when text changes
# =====================================================================

BASE="http://127.0.0.1:7070/"
DIR="/recalbox/share/userscripts/Pixelcade_kodimonitor"
LOG="$DIR/Pixelcade_kodimonitor.log"
PID_FILE="/tmp/Pixelcade_kodimonitor.pid"
SCRIPT_VERSION="persistent_tcp_pixelcade_sync_second_v8_compact"

LOG_ENABLED="0"
LOG_DETAIL_ENABLED="0"
RESTORE_PIXELCADE_ON_EXIT="1"
LAST_PIXELCADE_CURL_FILE="/recalbox/share/userscripts/lastcurlconsolegame.txt"

# Main timing. The loop wakes up on every system-second change.
SECOND_POLL_DELAY="0.02"
RPC_READ_CHAR_TIMEOUT="0.05"
RPC_MAX_EMPTY_READS="40"

# Display texts.
TXT_NO_PLAYBACK="No playback"
TXT_KODI_IDLE="KODI"
TXT_STATUS_PLAY="PLAY"
TXT_STATUS_PAUSE="PAUSE"
TXT_LIVE="LIVE"
TXT_VIEWERS="viewers"
TXT_VIEWS="views"

# Kodi metadata tuning.
TWITCH_INFO_REFRESH_SEC="1"
TV_STABILIZE_SEC="1"

# Pixelcade settings.
DOT_BRIGHTNESS="1"
DOT_FONT="0"
DOT_LOOPS="1"
DOT_SPEED="80"
SEG7_BRIGHTNESS="5"

# Last display cache.
LCD0_LAST=""
LCD1_LAST=""
LCD2_LAST=""
LCD3_LAST=""
DOT_LAST=""
SEG7_LAST=""
LAST_SECOND=""

# Twitch cache.
TWITCH_LAST_KEY=""
TWITCH_LAST_INFO_TS="0"
TWITCH_LAST_CHANNEL=""
TWITCH_LAST_TITLE=""
TWITCH_LAST_LINE3=""

# TV cache.
TV_LAST_CHANNEL=""
TV_LAST_CHANNEL_TS="0"

mkdir -p "$DIR"

# Single-instance lock.
if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null)"
  if [ "$OLD_PID" != "" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    exit 0
  fi
fi

echo $$ > "$PID_FILE"
CLEANUP_DONE="0"

log(){
  [ "$LOG_ENABLED" = "1" ] || return 0
  echo "$(date '+%F %T') $*" >> "$LOG"
}

log_detail(){
  [ "$LOG_ENABLED" = "1" ] || return 0
  [ "$LOG_DETAIL_ENABLED" = "1" ] || return 0
  echo "$(date '+%F %T') DETAIL $*" >> "$LOG"
}

cleanup(){
  [ "$CLEANUP_DONE" = "1" ] && exit 0
  CLEANUP_DONE="1"

  if [ "$RESTORE_PIXELCADE_ON_EXIT" = "1" ] && [ -s "$LAST_PIXELCADE_CURL_FILE" ]; then
    log "RESTORE_PIXELCADE run lastcurlconsolegame"
    bash -c "$(cat "$LAST_PIXELCADE_CURL_FILE")"
  fi

  rpc_close 2>/dev/null
  rm -f "$PID_FILE"
  exit 0
}

trap cleanup INT TERM EXIT

# ---------------------------------------------------------------------
# Kodi JSON-RPC over persistent TCP port 9090
# ---------------------------------------------------------------------

KODI_RPC_OPEN="0"

rpc_close(){
  if [ "$KODI_RPC_OPEN" = "1" ]; then
    exec 3>&- 2>/dev/null
    exec 3<&- 2>/dev/null
  fi
  KODI_RPC_OPEN="0"
}

rpc_open(){
  exec 3<>/dev/tcp/127.0.0.1/9090 || {
    KODI_RPC_OPEN="0"
    return 1
  }
  KODI_RPC_OPEN="1"
  log_detail "RPC_OPEN persistent TCP connection established"
}

rpc_request_id(){
  REQUEST_TEXT="$1"
  ID_VALUE="$(printf "%s" "$REQUEST_TEXT" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -n1)"
  [ "$ID_VALUE" != "" ] && { printf "%s" "$ID_VALUE"; return; }
  printf "%s" "$REQUEST_TEXT" | sed -n 's/.*"id":\([0-9][0-9]*\).*/\1/p' | head -n1
}

rpc_normalize_stream(){
  printf "%s" "$1" | tr -d '\r' | awk '{gsub(/\}\{"jsonrpc"/,"}\n{\"jsonrpc\""); print}'
}

rpc_extract_response(){
  EXPECTED_ID="$1"
  NORMALIZED="$(rpc_normalize_stream "$2")"

  if echo "$EXPECTED_ID" | grep -Eq '^[0-9][0-9]*$'; then
    printf "%s\n" "$NORMALIZED" | grep -E '"id":("'"$EXPECTED_ID"'"|'"$EXPECTED_ID"')([,}])' | head -n1
  else
    printf "%s\n" "$NORMALIZED" | grep '"id":"'"$EXPECTED_ID"'"' | head -n1
  fi
}

rpc_read_until_id(){
  EXPECTED_ID="$1"
  BUFFER=""
  EMPTY_READS="0"

  while [ "$EMPTY_READS" -lt "$RPC_MAX_EMPTY_READS" ]; do
    CH=""
    if IFS= read -r -t "$RPC_READ_CHAR_TIMEOUT" -n 1 CH <&3; then
      BUFFER="${BUFFER}${CH}"
      EMPTY_READS="0"
    else
      if [ "$BUFFER" != "" ]; then
        RESPONSE="$(rpc_extract_response "$EXPECTED_ID" "$BUFFER")"
        [ "$RESPONSE" != "" ] && { printf "%s" "$RESPONSE"; return 0; }
      fi
      EMPTY_READS=$((EMPTY_READS + 1))
    fi
  done

  log_detail "RPC_TIMEOUT id=[$EXPECTED_ID] buffered=[$(printf "%s" "$BUFFER" | tr -d '\r\n' | cut -c1-240)]"
  return 1
}

rpc(){
  REQUEST="$1"
  EXPECTED_ID="$(rpc_request_id "$REQUEST")"
  [ "$EXPECTED_ID" = "" ] && EXPECTED_ID="1"

  if [ "$KODI_RPC_OPEN" != "1" ]; then
    rpc_open || return 1
  fi

  printf "%s\r\n" "$REQUEST" >&3 2>/dev/null || {
    log_detail "RPC_WRITE_FAIL id=[$EXPECTED_ID] reconnecting"
    rpc_close
    rpc_open || return 1
    printf "%s\r\n" "$REQUEST" >&3 2>/dev/null || return 1
  }

  RESPONSE="$(rpc_read_until_id "$EXPECTED_ID")" || {
    rpc_close
    return 1
  }

  log_detail "RPC_RESPONSE id=[$EXPECTED_ID] text=[$(printf "%s" "$RESPONSE" | tr -d '\r\n' | cut -c1-240)]"
  printf "%s" "$RESPONSE"
}

# ---------------------------------------------------------------------
# Small JSON helpers. They are intentionally simple for Recalbox/Bash.
# ---------------------------------------------------------------------

json_string(){
  KEY="$1"
  JSON="$2"
  echo "$JSON" | sed -n "s/.*\"$KEY\":\"\([^\"]*\)\".*/\1/p" | head -n1
}

json_number(){
  KEY="$1"
  JSON="$2"
  echo "$JSON" | sed -n "s/.*\"$KEY\":\([0-9][0-9]*\).*/\1/p" | head -n1
}

json_float_integer_part(){
  KEY="$1"
  JSON="$2"
  echo "$JSON" | sed -n "s/.*\"$KEY\":\([0-9][0-9.]*\).*/\1/p" | head -n1 | cut -d. -f1
}

json_time_part(){
  KEY="$1"
  PART="$2"
  JSON="$3"

  case "$PART" in
    h) echo "$JSON" | sed -n "s/.*\"$KEY\":{\"hours\":\([0-9]*\),\"milliseconds\":[0-9]*,\"minutes\":[0-9]*,\"seconds\":[0-9]*}.*/\1/p" | head -n1 ;;
    m) echo "$JSON" | sed -n "s/.*\"$KEY\":{\"hours\":[0-9]*,\"milliseconds\":[0-9]*,\"minutes\":\([0-9]*\),\"seconds\":[0-9]*}.*/\1/p" | head -n1 ;;
    s) echo "$JSON" | sed -n "s/.*\"$KEY\":{\"hours\":[0-9]*,\"milliseconds\":[0-9]*,\"minutes\":[0-9]*,\"seconds\":\([0-9]*\)}.*/\1/p" | head -n1 ;;
  esac
}

# ---------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------

format_time(){
  HOURS="${1:-0}"
  MINUTES="${2:-0}"
  SECONDS="${3:-0}"

  if [ "$HOURS" -gt 0 ] 2>/dev/null; then
    printf "%d:%02d:%02d" "$HOURS" "$MINUTES" "$SECONDS"
  else
    printf "%02d:%02d" "$MINUTES" "$SECONDS"
  fi
}

format_seconds(){
  TOTAL_SECONDS="${1:-0}"
  [ "$TOTAL_SECONDS" -lt 0 ] 2>/dev/null && TOTAL_SECONDS="0"

  HOURS=$((TOTAL_SECONDS / 3600))
  MINUTES=$(((TOTAL_SECONDS % 3600) / 60))
  SECONDS=$((TOTAL_SECONDS % 60))
  format_time "$HOURS" "$MINUTES" "$SECONDS"
}

clean_text(){
  TEXT="$(printf "%s" "$1" | sed \
    -e 's/\\r\\n/ /g' -e 's/\\n/ /g' -e 's/\\r/ /g' \
    -e 's/é/e/g' -e 's/è/e/g' -e 's/ê/e/g' -e 's/ë/e/g' -e 's/É/E/g' -e 's/È/E/g' -e 's/Ê/E/g' -e 's/Ë/E/g' \
    -e 's/à/a/g' -e 's/â/a/g' -e 's/ä/a/g' -e 's/À/A/g' -e 's/Â/A/g' -e 's/Ä/A/g' \
    -e 's/î/i/g' -e 's/ï/i/g' -e 's/Î/I/g' -e 's/Ï/I/g' \
    -e 's/ô/o/g' -e 's/ö/o/g' -e 's/Ô/O/g' -e 's/Ö/O/g' \
    -e 's/ù/u/g' -e 's/û/u/g' -e 's/ü/u/g' -e 's/Ù/U/g' -e 's/Û/U/g' -e 's/Ü/U/g' \
    -e 's/ç/c/g' -e 's/Ç/C/g' -e 's/œ/oe/g' -e 's/Œ/OE/g' -e 's/æ/ae/g' -e 's/Æ/AE/g' \
    -e "s/’/'/g" -e "s/‘/'/g" -e 's/“/"/g' -e 's/”/"/g' -e 's/–/-/g' -e 's/—/-/g' -e 's/…/.../g')"

  printf "%s" "$TEXT" | tr '\r\n|' '   ' | LC_ALL=C tr -cd ' -~' | sed 's/  */ /g; s/^ //; s/ $//'
}

fit_lcd_20(){ printf "%-20.20s" "$(clean_text "$1")"; }
fit_dot_8(){ printf "%.8s" "$(clean_text "$1")"; }

url_encode_basic(){
  echo "$1" | sed \
    -e 's/%/%25/g' \
    -e 's/ /%20/g' \
    -e 's/&/%26/g' \
    -e 's/#/%23/g' \
    -e 's/+/%2B/g' \
    -e 's/?/%3F/g' \
    -e 's/=/%3D/g' \
    -e 's/:/%3A/g' \
    -e 's/\//%2F/g'
}

# ---------------------------------------------------------------------
# Pixelcade output
# ---------------------------------------------------------------------

pixelcade_api(){ curl -s "$1" >/dev/null 2>&1; }

lcd_line(){
  ROW="$1"
  TEXT="$(fit_lcd_20 "$2")"
  URL_TEXT="$(url_encode_basic "$TEXT")"

  case "$ROW" in
    0) [ "$TEXT" = "$LCD0_LAST" ] && return; LCD0_LAST="$TEXT" ;;
    1) [ "$TEXT" = "$LCD1_LAST" ] && return; LCD1_LAST="$TEXT" ;;
    2) [ "$TEXT" = "$LCD2_LAST" ] && return; LCD2_LAST="$TEXT" ;;
    3) [ "$TEXT" = "$LCD3_LAST" ] && return; LCD3_LAST="$TEXT" ;;
  esac

  pixelcade_api "${BASE}minilcd/centertext?text=${URL_TEXT}&row=${ROW}"
}

dot_matrix(){
  TEXT="$(fit_dot_8 "$1")"
  [ "$TEXT" = "" ] && TEXT="Kodi"
  [ "$TEXT" = "$DOT_LAST" ] && return
  DOT_LAST="$TEXT"

  pixelcade_api "${BASE}max7219/matrix/text?text=$(url_encode_basic "$TEXT")&brightness=${DOT_BRIGHTNESS}&font=${DOT_FONT}&loops=${DOT_LOOPS}&speed=${DOT_SPEED}"
}

seg7_clock(){
  # Space + decimal point separator, validated with Pixelcade MAX7219 API.
  CLOCK="$(date '+%Hh%M')%20.$(date '+%S')"
  [ "$CLOCK" = "$SEG7_LAST" ] && return
  SEG7_LAST="$CLOCK"

  pixelcade_api "${BASE}max7219/7seg/text?text=${CLOCK}&brightness=${SEG7_BRIGHTNESS}"
}

draw_all(){
  lcd_line 0 "$1"
  lcd_line 1 "$2"
  lcd_line 2 "$3"
  lcd_line 3 "$4"
  dot_matrix "$5"

  log "LCD=[$(clean_text "$1")][$(clean_text "$2")][$(clean_text "$3")][$(clean_text "$4")] DOT=[$(clean_text "$5")]"
  log_detail "DRAW_DONE l0=[$(clean_text "$1")] l1=[$(clean_text "$2")] l2=[$(clean_text "$3")] l3=[$(clean_text "$4")] dot=[$(clean_text "$5")]"
}

draw_idle(){
  TV_LAST_CHANNEL=""
  TV_LAST_CHANNEL_TS="0"
  TWITCH_LAST_KEY=""
  TWITCH_LAST_INFO_TS="0"
  TWITCH_LAST_CHANNEL=""
  TWITCH_LAST_TITLE=""
  TWITCH_LAST_LINE3=""
  draw_all "$TXT_KODI_IDLE" "$TXT_NO_PLAYBACK" "" "" "Kodi"
}

wait_next_second(){
  while true; do
    NOW_SECOND="$(date '+%S')"
    if [ "$NOW_SECOND" != "$LAST_SECOND" ]; then
      LAST_SECOND="$NOW_SECOND"
      return 0
    fi
    sleep "$SECOND_POLL_DELAY"
  done
}

# ---------------------------------------------------------------------
# Kodi/Twitch formatting helpers
# ---------------------------------------------------------------------

is_twitch_file(){ echo "$1" | grep -q 'plugin://plugin.video.twitch'; }
is_twitch_json(){ echo "$1" | grep -q 'plugin.video.twitch'; }
is_twitch_vod_text(){ echo "$1" | grep -Eq 'video_id=|Vues:|Views:'; }

url_decode_basic(){
  echo "$1" | sed \
    -e 's/%20/ /g' -e 's/%2B/+/g' -e 's/%2b/+/g' \
    -e 's/%2D/-/g' -e 's/%2d/-/g' \
    -e 's/%5F/_/g' -e 's/%5f/_/g'
}

extract_url_param(){
  JSON_TEXT="$1"
  PARAM_NAME="$2"
  printf "%s" "$JSON_TEXT" | sed -n "s/.*[?&]${PARAM_NAME}=\([^&)\"\\]*\).*/\1/p" | head -n1
}

extract_twitch_channel_id(){
  printf "%s" "$1" | sed -n 's/.*[?&]channel_id=\([0-9][0-9]*\).*/\1/p' | head -n1
}

make_twitch_channel_from_label(){
  SOURCE_TEXT="$(clean_text "$1")"
  CHANNEL="$(printf "%s" "$SOURCE_TEXT" | sed 's/[[:space:]]*-[[:space:]]*.*//')"
  [ "$CHANNEL" = "" ] && CHANNEL="$SOURCE_TEXT"
  clean_text "$CHANNEL"
}

make_twitch_title_from_label(){
  SOURCE_TEXT="$(clean_text "$1")"
  TITLE="$(printf "%s" "$SOURCE_TEXT" | sed 's/^[^-]*[[:space:]]*-[[:space:]]*//')"
  TITLE="$(printf "%s" "$TITLE" | sed -e 's/^LIVE[[:space:]]*//' -e 's/^Live[[:space:]]*//' -e 's/^live[[:space:]]*//')"
  [ "$TITLE" = "$SOURCE_TEXT" ] && TITLE=""
  clean_text "$TITLE"
}

strip_twitch_channel_prefix(){
  CHANNEL="$(clean_text "$1")"
  TITLE_TEXT="$(clean_text "$2")"
  [ "$CHANNEL" = "" ] && { clean_text "$TITLE_TEXT"; return; }

  STRIPPED="$(printf "%s" "$TITLE_TEXT" | sed \
    -e "s/^${CHANNEL}[[:space:]]*-[[:space:]]*//" \
    -e 's/^LIVE[[:space:]]*//' \
    -e 's/^Live[[:space:]]*//' \
    -e 's/^live[[:space:]]*//')"
  clean_text "$STRIPPED"
}

make_twitch_channel(){
  ITEM_JSON="$1"
  FALLBACK_LABEL="$2"

  CHANNEL="$(extract_url_param "$ITEM_JSON" "display_name")"
  [ "$CHANNEL" = "" ] && CHANNEL="$(extract_url_param "$ITEM_JSON" "channel_name")"
  [ "$CHANNEL" = "" ] && CHANNEL="$(extract_url_param "$ITEM_JSON" "name")"
  CHANNEL="$(url_decode_basic "$CHANNEL")"

  [ "$CHANNEL" = "" ] && CHANNEL="$(make_twitch_channel_from_label "$FALLBACK_LABEL")"
  clean_text "$CHANNEL"
}

make_dot_text(){
  SOURCE_TEXT="$(clean_text "$1")"
  SOURCE_FILE="$(clean_text "$2")"
  DOT_TEXT="$SOURCE_TEXT"

  if echo "$SOURCE_FILE" | grep -q 'plugin://plugin.video.twitch'; then
    DOT_TEXT="$(printf "%s" "$DOT_TEXT" | sed -e 's/ - LIVE.*//' -e 's/ - Live.*//' -e 's/ - live.*//')"
  fi

  [ "$DOT_TEXT" = "" ] && DOT_TEXT="Kodi"
  fit_dot_8 "$DOT_TEXT"
}

is_probable_tv_channel_name(){
  NAME="$(clean_text "$1")"
  [ "$NAME" = "" ] && return 1
  [ "${#NAME}" -gt 18 ] && return 1

  echo "$NAME" | grep -Eq '[0-9]' && return 0
  UPPER="$(printf "%s" "$NAME" | tr '[:lower:]' '[:upper:]')"
  [ "$NAME" = "$UPPER" ] && return 0
  echo "$NAME" | grep -Eq '^(France|Canal|Arte|RMC|BFM|CNEWS|LCI|Gulli|TF1|TMC|M6|W9)' && return 0
  return 1
}

sanitize_twitch_line3(){
  LINE3="$(clean_text "$1")"
  CHANNEL="$(clean_text "$2")"
  TITLE_TEXT="$(clean_text "$3")"

  [ "$LINE3" = "" ] && { clean_text "$TXT_LIVE"; return; }
  [ "$CHANNEL" != "" ] && [ "$LINE3" = "$CHANNEL" ] && { clean_text "$TXT_LIVE"; return; }
  [ "$TITLE_TEXT" != "" ] && [ "$LINE3" = "$TITLE_TEXT" ] && { clean_text "$TXT_LIVE"; return; }

  echo "$LINE3" | grep -Eq '/|viewers|viewer|views|view|LIVE|live|[0-9]+:[0-9]' && { clean_text "$LINE3"; return; }
  clean_text "$TXT_LIVE"
}

twitch_playlist_matches_current(){
  PLAYLIST_JSON="$1"
  PLAYLIST_LABEL="$2"
  PLAYLIST_FILE="$3"
  CURRENT_FILE="$4"
  CURRENT_CHANNEL="$5"

  CURRENT_ID="$(extract_twitch_channel_id "$CURRENT_FILE")"
  PLAYLIST_ID="$(extract_twitch_channel_id "$PLAYLIST_FILE")"
  [ "$PLAYLIST_ID" = "" ] && PLAYLIST_ID="$(extract_twitch_channel_id "$PLAYLIST_JSON")"

  if [ "$CURRENT_ID" != "" ] && [ "$PLAYLIST_ID" != "" ]; then
    [ "$CURRENT_ID" = "$PLAYLIST_ID" ] && return 0
    return 1
  fi

  PLAYLIST_CHANNEL="$(make_twitch_channel "$PLAYLIST_JSON" "$PLAYLIST_LABEL")"
  [ "$PLAYLIST_CHANNEL" = "" ] && return 1
  [ "$(clean_text "$PLAYLIST_CHANNEL")" = "$(clean_text "$CURRENT_CHANNEL")" ]
}

make_twitch_info_line(){
  PLOT_TEXT="$(clean_text "$1")"
  LIVE_TIME="$2"
  PLAYBACK_LINE="$3"

  GAME="$(printf "%s" "$PLOT_TEXT" | sed -n 's/.*Jeu:[[:space:]]*\(.*\)[[:space:]]*Spectateurs:.*/\1/p' | sed 's/[[:space:]]*$//')"
  VIEWERS="$(printf "%s" "$PLOT_TEXT" | sed -n 's/.*Spectateurs:[[:space:]]*\([0-9][0-9]*\).*/\1/p')"
  [ "$GAME" = "" ] && GAME="$(printf "%s" "$PLOT_TEXT" | sed -n 's/.*Game:[[:space:]]*\(.*\)[[:space:]]*Viewers:.*/\1/p' | sed 's/[[:space:]]*$//')"
  [ "$VIEWERS" = "" ] && VIEWERS="$(printf "%s" "$PLOT_TEXT" | sed -n 's/.*Viewers:[[:space:]]*\([0-9][0-9]*\).*/\1/p')"

  VOD_VIEWS="$(printf "%s" "$PLOT_TEXT" | sed -n 's/.*Vues:[[:space:]]*\([0-9][0-9]*\).*/\1/p')"
  [ "$VOD_VIEWS" = "" ] && VOD_VIEWS="$(printf "%s" "$PLOT_TEXT" | sed -n 's/.*Views:[[:space:]]*\([0-9][0-9]*\).*/\1/p')"

  if [ "$VOD_VIEWS" != "" ]; then
    if [ "$PLAYBACK_LINE" != "" ] && [ "$PLAYBACK_LINE" != "00:00/00:00" ] && [ "$PLAYBACK_LINE" != "00:00/00:00 0%" ]; then
      clean_text "${PLAYBACK_LINE} ${VOD_VIEWS} ${TXT_VIEWS}"
    elif [ "$LIVE_TIME" != "" ]; then
      clean_text "${LIVE_TIME} ${VOD_VIEWS} ${TXT_VIEWS}"
    else
      clean_text "${VOD_VIEWS} ${TXT_VIEWS}"
    fi
  elif [ "$GAME" != "" ] && [ "$VIEWERS" != "" ]; then
    clean_text "${GAME} / ${VIEWERS} ${TXT_VIEWERS}"
  elif [ "$GAME" != "" ] && [ "$LIVE_TIME" != "" ]; then
    clean_text "${GAME} / ${TXT_LIVE} ${LIVE_TIME}"
  elif [ "$VIEWERS" != "" ]; then
    clean_text "${VIEWERS} ${TXT_VIEWERS}"
  elif [ "$PLAYBACK_LINE" != "" ] && [ "$PLAYBACK_LINE" != "00:00/00:00" ] && [ "$PLAYBACK_LINE" != "00:00/00:00 0%" ]; then
    clean_text "$PLAYBACK_LINE"
  elif [ "$LIVE_TIME" != "" ]; then
    clean_text "${LIVE_TIME} ${TXT_LIVE}"
  else
    clean_text "$TXT_LIVE"
  fi
}

# ---------------------------------------------------------------------
# Player context and media handlers
# ---------------------------------------------------------------------

load_player_context(){
  ITEM_INFO="$(rpc "{\"jsonrpc\":\"2.0\",\"method\":\"Player.GetItem\",\"params\":{\"playerid\":${KODI_PLAYER_ID},\"properties\":[\"title\",\"showtitle\",\"season\",\"episode\",\"file\",\"customproperties\",\"mediapath\",\"dynpath\"]},\"id\":\"item\"}" 2>/dev/null)"
  PLAYER_INFO="$(rpc "{\"jsonrpc\":\"2.0\",\"method\":\"Player.GetProperties\",\"params\":{\"playerid\":${KODI_PLAYER_ID},\"properties\":[\"speed\",\"time\",\"totaltime\",\"percentage\"]},\"id\":\"props\"}" 2>/dev/null)"

  LABEL="$(clean_text "$(json_string label "$ITEM_INFO")")"
  TITLE="$(clean_text "$(json_string title "$ITEM_INFO")")"
  SHOW_TITLE="$(clean_text "$(json_string showtitle "$ITEM_INFO")")"
  MEDIA_TYPE="$(clean_text "$(json_string type "$ITEM_INFO")")"
  FILE_PATH="$(clean_text "$(json_string file "$ITEM_INFO")")"
  CHANNEL_FIELD="$(clean_text "$(json_string channel "$ITEM_INFO")")"

  [ "$LABEL$TITLE$SHOW_TITLE$FILE_PATH" = "" ] && return 1

  SPEED="$(json_number speed "$PLAYER_INFO")"
  PERCENT="$(json_float_integer_part percentage "$PLAYER_INFO")"
  [ "$SPEED" = "0" ] && STATUS="$TXT_STATUS_PAUSE" || STATUS="$TXT_STATUS_PLAY"

  CURRENT_TIME="$(format_time "$(json_time_part time h "$PLAYER_INFO")" "$(json_time_part time m "$PLAYER_INFO")" "$(json_time_part time s "$PLAYER_INFO")")"
  TOTAL_TIME="$(format_time "$(json_time_part totaltime h "$PLAYER_INFO")" "$(json_time_part totaltime m "$PLAYER_INFO")" "$(json_time_part totaltime s "$PLAYER_INFO")")"

  LINE_TIME="${CURRENT_TIME}/${TOTAL_TIME}"
  [ "$PERCENT" != "" ] && LINE_TIME="${LINE_TIME} ${PERCENT}%"
  PLAYBACK_TIME="${CURRENT_TIME}/${TOTAL_TIME}"
}

handle_tv(){
  TV_CHANNEL="$CHANNEL_FIELD"
  [ "$TV_CHANNEL" = "" ] && TV_CHANNEL="$LABEL"
  TV_PROGRAM="$TITLE"
  TV_LINE3="$LINE_TIME"
  NOW_TS="$(date '+%s')"

  if [ "$TV_CHANNEL" = "" ] && [ "$TV_PROGRAM" != "" ]; then
    TV_CHANNEL="$TV_PROGRAM"
    TV_PROGRAM=""
  elif [ "$TV_PROGRAM" != "" ] && [ "$TV_PROGRAM" = "$TV_CHANNEL" ]; then
    TV_PROGRAM=""
  elif [ "$TV_PROGRAM" != "" ] && [ "$TV_PROGRAM" != "$TV_CHANNEL" ] && is_probable_tv_channel_name "$TV_PROGRAM"; then
    TV_CHANNEL="$TV_PROGRAM"
    TV_PROGRAM=""
  fi

  echo "$TV_LINE3" | grep -q '^00:00/00:00' && TV_LINE3="$TXT_LIVE"

  if [ "$TV_CHANNEL" != "$TV_LAST_CHANNEL" ]; then
    TV_LAST_CHANNEL="$TV_CHANNEL"
    TV_LAST_CHANNEL_TS="$NOW_TS"
    TV_PROGRAM=""
  else
    TV_AGE=$((NOW_TS - TV_LAST_CHANNEL_TS))
    [ "$TV_AGE" -lt "$TV_STABILIZE_SEC" ] && TV_PROGRAM=""
  fi

  [ "$TV_CHANNEL" = "" ] && TV_CHANNEL="$TXT_LIVE"
  draw_all "KODI TV ${STATUS}" "$TV_CHANNEL" "$TV_PROGRAM" "$TV_LINE3" "$(make_dot_text "$TV_CHANNEL" "$FILE_PATH")"
}

handle_series(){
  TV_LAST_CHANNEL=""
  TV_LAST_CHANNEL_TS="0"
  draw_all "KODI SERIES ${STATUS}" "$SHOW_TITLE" "$TITLE" "$LINE_TIME" "$(make_dot_text "$SHOW_TITLE" "$FILE_PATH")"
}

set_twitch_safe_cache(){
  SAFE_KEY="$1"
  SAFE_CHANNEL="$2"
  SAFE_TITLE="$3"
  SAFE_LINE3="$4"

  TWITCH_LAST_KEY="$SAFE_KEY"
  TWITCH_LAST_INFO_TS="0"
  TWITCH_LAST_CHANNEL="$SAFE_CHANNEL"
  TWITCH_LAST_TITLE="$(strip_twitch_channel_prefix "$SAFE_CHANNEL" "$SAFE_TITLE")"
  [ "$TWITCH_LAST_TITLE" = "" ] && TWITCH_LAST_TITLE="$SAFE_TITLE"
  TWITCH_LAST_LINE3="$(sanitize_twitch_line3 "$SAFE_LINE3" "$TWITCH_LAST_CHANNEL" "$TWITCH_LAST_TITLE")"
}

refresh_twitch_playlist(){
  TWITCH_PLAYLIST="$(rpc '{"jsonrpc":"2.0","method":"Playlist.GetItems","params":{"playlistid":1,"properties":["title","file","plot","plotoutline","tagline","thumbnail","fanart","customproperties","mediapath","dynpath","genre","duration"]},"id":"playlist"}' 2>/dev/null)"

  PLAYLIST_LABEL="$(clean_text "$(json_string label "$TWITCH_PLAYLIST")")"
  PLAYLIST_FILE="$(clean_text "$(json_string file "$TWITCH_PLAYLIST")")"
  PLAYLIST_TITLE="$(clean_text "$(json_string tagline "$TWITCH_PLAYLIST")")"
  PLAYLIST_PLOT="$(clean_text "$(json_string plot "$TWITCH_PLAYLIST")")"
  PLAYLIST_DURATION="$(json_number duration "$TWITCH_PLAYLIST")"

  TWITCH_PLAYBACK_TIME="$PLAYBACK_TIME"
  if [ "$TOTAL_TIME" = "00:00" ] && [ "$PLAYLIST_DURATION" != "" ] && [ "$PLAYLIST_DURATION" -gt 0 ] 2>/dev/null; then
    TWITCH_PLAYBACK_TIME="${CURRENT_TIME}/$(format_seconds "$PLAYLIST_DURATION")"
  fi

  if (is_twitch_file "$PLAYLIST_FILE" || is_twitch_json "$TWITCH_PLAYLIST") && \
     twitch_playlist_matches_current "$TWITCH_PLAYLIST" "$PLAYLIST_LABEL" "$PLAYLIST_FILE" "$FILE_PATH" "$TWITCH_CHANNEL_CURRENT"; then
    TWITCH_CHANNEL="$(make_twitch_channel "$TWITCH_PLAYLIST" "$PLAYLIST_LABEL")"
    [ "$TWITCH_CHANNEL" = "" ] && TWITCH_CHANNEL="$TWITCH_CHANNEL_CURRENT"

    TWITCH_TITLE="$PLAYLIST_TITLE"
    [ "$TWITCH_TITLE" = "" ] && TWITCH_TITLE="$(make_twitch_title_from_label "$PLAYLIST_LABEL")"
    [ "$TWITCH_TITLE" = "" ] && TWITCH_TITLE="$TWITCH_TITLE_CURRENT"
    TWITCH_TITLE="$(strip_twitch_channel_prefix "$TWITCH_CHANNEL" "$TWITCH_TITLE")"

    TWITCH_LINE3="$(make_twitch_info_line "$PLAYLIST_PLOT" "$CURRENT_TIME" "$TWITCH_PLAYBACK_TIME")"
    TWITCH_LINE3="$(sanitize_twitch_line3 "$TWITCH_LINE3" "$TWITCH_CHANNEL" "$TWITCH_TITLE")"
    [ "$TWITCH_LINE3" = "" ] && TWITCH_LINE3="$TXT_LIVE"

    TWITCH_LAST_INFO_TS="$NOW_TS"
    TWITCH_LAST_CHANNEL="$TWITCH_CHANNEL"
    TWITCH_LAST_TITLE="$TWITCH_TITLE"
    TWITCH_LAST_LINE3="$TWITCH_LINE3"
    log "TWITCH_PLAYLIST_REFRESH channel=[$(clean_text "$TWITCH_CHANNEL")] title=[$(clean_text "$TWITCH_TITLE")] info=[$(clean_text "$TWITCH_LINE3")]"
  elif is_twitch_file "$PLAYLIST_FILE" || is_twitch_json "$TWITCH_PLAYLIST"; then
    set_twitch_safe_cache "$TWITCH_KEY" "$TWITCH_CHANNEL_CURRENT" "$TWITCH_TITLE_CURRENT" "$TWITCH_LINE3_CURRENT"
    log "TWITCH_PLAYLIST_STALE_SAFE current=[$(clean_text "$TWITCH_CHANNEL_CURRENT")] playlist=[$(clean_text "$PLAYLIST_LABEL")]"
  else
    TWITCH_LAST_INFO_TS="0"
    log "TWITCH_PLAYLIST_EMPTY fallback_channel=[$(clean_text "$TWITCH_LAST_CHANNEL")]"
  fi
}

handle_twitch(){
  TWITCH_CHANNEL_CURRENT="$(make_twitch_channel "$ITEM_INFO" "$MAIN_TITLE")"
  [ "$TWITCH_CHANNEL_CURRENT" = "" ] && TWITCH_CHANNEL_CURRENT="$(make_twitch_channel_from_label "$MAIN_TITLE")"
  [ "$TWITCH_CHANNEL_CURRENT" = "" ] && TWITCH_CHANNEL_CURRENT="$MAIN_TITLE"

  TWITCH_TITLE_CURRENT="$(make_twitch_title_from_label "$MAIN_TITLE")"
  [ "$TWITCH_TITLE_CURRENT" = "" ] && TWITCH_TITLE_CURRENT="$MAIN_TITLE"

  if is_twitch_vod_text "$FILE_PATH$ITEM_INFO$MAIN_TITLE"; then
    TWITCH_LINE3_CURRENT="$PLAYBACK_TIME"
  else
    TWITCH_LINE3_CURRENT="$TXT_LIVE"
  fi

  TWITCH_KEY="${FILE_PATH}|${MAIN_TITLE}|${TWITCH_CHANNEL_CURRENT}"
  NOW_TS="$(date '+%s')"

  if [ "$TWITCH_KEY" != "$TWITCH_LAST_KEY" ]; then
    set_twitch_safe_cache "$TWITCH_KEY" "$TWITCH_CHANNEL_CURRENT" "$TWITCH_TITLE_CURRENT" "$TWITCH_LINE3_CURRENT"
    draw_all "KODI TWITCH ${STATUS}" "$TWITCH_LAST_CHANNEL" "$TWITCH_LAST_TITLE" "$TWITCH_LAST_LINE3" "$(fit_dot_8 "$TWITCH_LAST_CHANNEL")"
    return 0
  fi

  if [ "$TWITCH_INFO_REFRESH_SEC" != "0" ]; then
    TWITCH_INFO_AGE=$((NOW_TS - TWITCH_LAST_INFO_TS))
    [ "$TWITCH_INFO_AGE" -ge "$TWITCH_INFO_REFRESH_SEC" ] && refresh_twitch_playlist
  fi

  draw_all "KODI TWITCH ${STATUS}" "$TWITCH_LAST_CHANNEL" "$TWITCH_LAST_TITLE" "$TWITCH_LAST_LINE3" "$(fit_dot_8 "$TWITCH_LAST_CHANNEL")"
}

handle_pending_twitch_or_video(){
  if [ "$TWITCH_LAST_KEY" != "" ] && [ "$FILE_PATH" = "" ] && echo "$MAIN_TITLE" | grep -q ' - '; then
    TWITCH_CHANNEL_PENDING="$(make_twitch_channel_from_label "$MAIN_TITLE")"
    TWITCH_TITLE_PENDING="$(make_twitch_title_from_label "$MAIN_TITLE")"
    [ "$TWITCH_CHANNEL_PENDING" = "" ] && TWITCH_CHANNEL_PENDING="$MAIN_TITLE"
    [ "$TWITCH_TITLE_PENDING" = "" ] && TWITCH_TITLE_PENDING="$TXT_LIVE"

    set_twitch_safe_cache "pending|${MAIN_TITLE}|${TWITCH_CHANNEL_PENDING}" "$TWITCH_CHANNEL_PENDING" "$TWITCH_TITLE_PENDING" "$TXT_LIVE"
    draw_all "KODI TWITCH ${STATUS}" "$TWITCH_LAST_CHANNEL" "$TWITCH_LAST_TITLE" "$TWITCH_LAST_LINE3" "$(fit_dot_8 "$TWITCH_LAST_CHANNEL")"
    return 0
  fi

  TWITCH_LAST_KEY=""
  TWITCH_LAST_INFO_TS="0"
  TWITCH_LAST_CHANNEL=""
  TWITCH_LAST_TITLE=""
  TWITCH_LAST_LINE3=""

  draw_all "KODI VIDEO ${STATUS}" "$MAIN_TITLE" "" "$LINE_TIME" "$(make_dot_text "$MAIN_TITLE" "$FILE_PATH")"
}

handle_video(){
  TV_LAST_CHANNEL=""
  TV_LAST_CHANNEL_TS="0"

  MAIN_TITLE="$TITLE"
  [ "$MAIN_TITLE" = "" ] && MAIN_TITLE="$LABEL"
  if [ "$MAIN_TITLE" = "" ]; then
    MAIN_TITLE="${FILE_PATH##*/}"
    MAIN_TITLE="${MAIN_TITLE%.*}"
  fi

  if is_twitch_file "$FILE_PATH" || is_twitch_json "$ITEM_INFO"; then
    handle_twitch
  else
    handle_pending_twitch_or_video
  fi
}

update_kodi_displays(){
  ACTIVE_PLAYERS="$(rpc '{"jsonrpc":"2.0","method":"Player.GetActivePlayers","id":"active"}' 2>/dev/null)"
  if [ "$ACTIVE_PLAYERS" = "" ]; then
    log "Kodi JSON-RPC lost, exiting"
    cleanup
  fi

  KODI_PLAYER_ID="$(json_number playerid "$ACTIVE_PLAYERS")"
  [ "$KODI_PLAYER_ID" = "" ] && { draw_idle; return 0; }

  load_player_context || return 0

  case "$MEDIA_TYPE" in
    channel) handle_tv ;;
    *)
      if [ "$SHOW_TITLE" != "" ]; then
        handle_series
      else
        handle_video
      fi
      ;;
  esac
}

# ---------------------------------------------------------------------
# Startup and main loop
# ---------------------------------------------------------------------

log "Kodi monitor started version=${SCRIPT_VERSION}"
WAIT_COUNT="0"

while true; do
  PING_RESPONSE="$(rpc '{"jsonrpc":"2.0","method":"JSONRPC.Ping","id":"ping"}' 2>/dev/null)"
  echo "$PING_RESPONSE" | grep -q '"result":"pong"' && break

  WAIT_COUNT=$((WAIT_COUNT + 1))
  if [ "$WAIT_COUNT" -gt 30 ]; then
    log "Kodi JSON-RPC not available, exiting"
    cleanup
  fi
  sleep 1
done

# First visible state at Kodi startup, before waiting for the next second.
LAST_SECOND="$(date '+%S')"
seg7_clock
draw_idle

while true; do
  wait_next_second
  seg7_clock
  update_kodi_displays
done
