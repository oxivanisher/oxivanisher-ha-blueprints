#!/usr/bin/env bash
# Control the "Hörbuch vorlesen" and "Hörbuch-Schlaftimer" blueprints via the
# Home Assistant REST API.
#
# Usage:
#   hoerbuch.sh start | stop | toggle
#   hoerbuch.sh sleep [MINUTES]   # default length from the blueprint if omitted
#   hoerbuch.sh sleep cancel
#
# Configuration (environment variables, or put them in ~/.config/hoerbuch.env):
#   HA_URL    e.g. http://homeassistant.example.lan:8123
#   HA_TOKEN  a long-lived access token (profile -> Security)
#   HA_PLAYER optional, comma-separated players instead of the automation's
#             "Feste Player", e.g. media_player.wohnung

set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/hoerbuch.env"
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
    data="${data%\}}, \"player\": [${players%,}]}"
  fi
  curl -fsS -X POST "${HA_URL%/}/api/events/$event" \
    -H "Authorization: Bearer $HA_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$data"
  echo
}

case "${1:-}" in
  start)  fire hoerbuch_vorlesen '{"aktion": "start"}' ;;
  stop)   fire hoerbuch_vorlesen '{"aktion": "stopp"}' ;;
  toggle) fire hoerbuch_vorlesen '{"aktion": "umschalten"}' ;;
  sleep)
    case "${2:-}" in
      "")      fire hoerbuch_schlaftimer_stellen '{"aktion": "start"}' ;;
      cancel)  fire hoerbuch_schlaftimer_stellen '{"aktion": "abbrechen"}' ;;
      *[!0-9]*) usage ;;
      *)       fire hoerbuch_schlaftimer_stellen "{\"aktion\": \"start\", \"minuten\": $2}" ;;
    esac
    ;;
  *) usage ;;
esac
