#!/usr/bin/env bash
# Control the "Hörbuch vorlesen" and "Hörbuch-Schlaftimer" blueprints via the
# Home Assistant REST API.
#
# Usage:
#   audiobook.sh start | stop | toggle
#   audiobook.sh sleep [MINUTES]   # default length from the blueprint if omitted
#   audiobook.sh sleep cancel
#
# Configuration (environment variables, or put them in ~/.config/audiobook.env):
#   HA_URL    e.g. http://homeassistant.example.lan:8123
#   HA_TOKEN  a long-lived access token (profile -> Security)
#   HA_PLAYER optional, comma-separated players instead of the automation's
#             "Feste Player", e.g. media_player.wohnung

set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/audiobook.env"
# shellcheck source=/dev/null
[[ -f "$config" ]] && source "$config"

: "${HA_URL:?HA_URL is not set}"
: "${HA_TOKEN:?HA_TOKEN is not set}"

usage() {
  echo "Usage: $(basename "$0") start|stop|toggle|sleep [MINUTES|cancel]" >&2
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

case "${1:-}" in
  start)  fire audiobook_play '{"action": "start"}' ;;
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
  *) usage ;;
esac
