#!/usr/bin/env bash
# Control the "Hörbuch vorlesen" and "Hörbuch-Schlaftimer" blueprints via the
# Home Assistant REST API.
#
# Usage:
#   audiobook.sh start [PERCENT]   # optional start volume, overrides "Start-Lautstärke"
#   audiobook.sh stop | toggle
#   audiobook.sh sleep [MINUTES]   # default length from the blueprint if omitted
#   audiobook.sh sleep cancel
#   audiobook.sh vol up | down      # one volume step (step size set by the player)
#   audiobook.sh vol PERCENT        # set volume, 0 to 100
#
# Configuration (environment variables, or put them in ~/.config/audiobook.env):
#   HA_URL    e.g. http://homeassistant.example.lan:8123
#   HA_TOKEN  a long-lived access token (profile -> Security)
#   HA_PLAYER optional, comma-separated players instead of the automation's
#             "Feste Player", e.g. media_player.wohnung
#   HA_VOLUME_PLAYER  player(s) for "vol", e.g. media_player.wohnung.
#             Falls back to HA_PLAYER. Needed because volume is a plain HA
#             action, not a blueprint event.

set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/audiobook.env"
# shellcheck source=/dev/null
[[ -f "$config" ]] && source "$config"

: "${HA_URL:?HA_URL is not set}"
: "${HA_TOKEN:?HA_TOKEN is not set}"

usage() {
  echo "Usage: $(basename "$0") start [PERCENT]|stop|toggle|sleep [MINUTES|cancel]|vol up|down|PERCENT" >&2
  exit 1
}

fire() {
  local event="$1" data="$2"
  if [[ -n "${HA_PLAYER:-}" ]]; then
    local players
    players=$(printf '"%s",' ${HA_PLAYER//,/ })
    data="${data%\}}, \"players\": [${players%,}]}"
  fi
  curl -fsS -X POST "${HA_URL%/}/api/events/$event" \
    -H "Authorization: Bearer $HA_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$data"
  echo
}

# Calls a Home Assistant action (service) on the volume player(s)
call() {
  local action="$1" extra="${2:-}"
  local target="${HA_VOLUME_PLAYER:-${HA_PLAYER:-}}"
  [[ -n "$target" ]] || { echo "HA_VOLUME_PLAYER (or HA_PLAYER) is not set" >&2; exit 1; }
  local entities
  entities=$(printf '"%s",' ${target//,/ })
  curl -fsS -o /dev/null -X POST "${HA_URL%/}/api/services/media_player/$action" \
    -H "Authorization: Bearer $HA_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"entity_id\": [${entities%,}]$extra}"
  echo "OK: media_player.$action"
}

case "${1:-}" in
  start)
    case "${2:-}" in
      "")      fire audiobook_play '{"action": "start"}' ;;
      *[!0-9]*) usage ;;
      *)       (( 10#$2 <= 100 )) || usage
               fire audiobook_play "{\"action\": \"start\", \"volume\": $(( 10#$2 ))}" ;;
    esac
    ;;
  stop)   fire audiobook_play '{"action": "stop"}' ;;
  toggle) fire audiobook_play '{"action": "toggle"}' ;;
  sleep)
    case "${2:-}" in
      "")      fire audiobook_sleep_timer '{"action": "start"}' ;;
      cancel)  fire audiobook_sleep_timer '{"action": "cancel"}' ;;
      *[!0-9]*) usage ;;
      *)       fire audiobook_sleep_timer "{\"action\": \"start\", \"minutes\": $2}" ;;
    esac
    ;;
  vol)
    case "${2:-}" in
      up)       call volume_up ;;
      down)     call volume_down ;;
      ""|*[!0-9]*) usage ;;
      *)
        percent=$(( 10#$2 ))
        (( percent <= 100 )) || usage
        call volume_set ", \"volume_level\": $(printf '%d.%02d' $(( percent / 100 )) $(( percent % 100 )))"
        ;;
    esac
    ;;
  *) usage ;;
esac
