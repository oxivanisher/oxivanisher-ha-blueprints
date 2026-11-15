# Project context

Public repository of Home Assistant blueprints, developed together with Claude. This file carries the context from the original chat so work can continue in an IDE. Read `docs/history.md` for the full background.

## Goal

Share fully local, German-language voice automations for Home Assistant Assist and Voice PE devices as importable blueprints.

## Conventions

- Blueprints live in `blueprints/<domain>/<name>.yaml` (domain = `automation` or `script`).
- User-facing texts (input names and descriptions, responses, notifications), voice sentences and comments in the blueprints are German. Identifiers are English: input keys, variables, trigger IDs, slot names, event types and event data keys. README and repo docs are English.
- One blueprint should be self-contained (single import). Prefer patterns that avoid needing a separate script (see "event self-trigger" below).
- Use current HA syntax: `triggers:` / `trigger:`, `actions:` / `action:`, `conditions:`.
- Keep `source_url` in each blueprint pointing at its raw location in this repo, so users can re-import updates.
- Avoid backslashes in Jinja regexes inside YAML block scalars; use character classes like `[ ]`, `[0-9]`, `[.]` instead.
- Quote or use block scalars (`>`) for any text containing `": "`; an unquoted colon breaks the import (this bug happened once).
- No secrets, tokens, IPs or personal data in this repo.
- Run `python3 scripts/validate.py` after changing a blueprint. It only checks YAML structure; real testing happens in HA (import the blueprint, then use the pipeline debug view).

## Patterns in use

- **Conversation trigger with wildcards**: `"Erinnere mich in {dauer} an {sache}"`, values in `trigger.slots`. Use `trigger.slots.get('x', '')` because not every trigger has every slot.
- **Event self-trigger**: the automation (`mode: parallel`) fires a custom event, and a second trigger in the same automation catches it and does the long `delay`. This returns the conversation response immediately while waiting in the background. Filter on `trigger.event.data.source == this.entity_id` so multiple instances don't react to each other.
- **Announce** with `assist_satellite.announce`, targeting `trigger.device_id` (the device that heard the command) or a configured list of satellites.

## Status

- `blueprints/automation/sprach_erinnerung.yaml`: working in the owner's setup (duration in seconds/minutes/hours and combinations, clock time "um HH:MM"). `source_url` and the README import badge point at github.com/oxivanisher/oxivanisher-ha-blueprints.

- `blueprints/automation/hoerbuch_schlaftimer.yaml`: sleep timer for Music Assistant / audiobooks. Not yet tested in HA. It uses the event self-trigger pattern. The internal `audiobook_sleep_timer_internal` event carries `source`; external control (dashboard, Node-RED, REST API) uses the public `audiobook_sleep_timer` event (`action` `start`/`cancel`, optional `minutes`, `players`, `device`), handled by the same code as the voice triggers. Without `players` and fixed players, it uses the currently playing MA players (members of a playing group left out). Like stopping, the timer is group-aware: a player that belongs to a playing MA group is replaced by that group, so all rooms fade and stop together. The background run waits in a `wait_for_trigger` loop, so a newer timer or a cancel for an overlapping player ends it. If no players are configured, it picks the player by the area of `trigger.device_id`. If nothing is playing, it can optionally start the book through the `audiobook_play` event. After pausing, it clears the MA queue (`media_player.clear_playlist`), so a stale position does not stick when the book is continued on another device.

- `blueprints/automation/hoerbuch_vorlesen.yaml`: plays the most recent in-progress Audiobookshelf book through Music Assistant (`play_media` by title). Not yet tested in HA. It needs a user-defined `rest_command.audiobookshelf_in_progress` (GET `/api/me/items-in-progress`, Bearer token in `secrets.yaml`), so it is not fully self-contained. That is unavoidable, because blueprints can't make HTTP calls. Music Assistant's `get_library` `last_played` sort was rejected as unreliable for Audiobookshelf. Besides the voice trigger it listens for an `audiobook_play` event (data: `action` `start`/`stop`/`toggle`, default `start`; `toggle` stops if a target player or a group containing it is playing, else starts; optional `players` list, default the fixed players; optional `device`). The sleep timer fires it when nothing is playing, and dashboard scripts use it for start/stop buttons (examples in the README). Errors from event-triggered runs go to a persistent notification, an `audiobook_error` event (`source`, `message`) and, if `device` is set, an announcement. Stopping is group-aware: a playing MA group is paused instead of the single speaker. A player counts as a member if it is in the group's `group_members` or has the same `active_queue` as the group. Only a player with `mass_player_type: group` or a sync leader (itself first in `group_members`) counts as a group: members of an MA sync group share the group's `active_queue` and report several `group_members`, so a looser test picked the members instead of the group (seen in the owner's logs: seek/pause were redirected by MA, but `clear_playlist` hit the members' own queues and the group's queue stayed). A target that is itself a group is never replaced. MA sync groups (`mass_player_type: group`) list their members in `group_members` (confirmed in the owner's setup); `active_queue` is only a fallback. An empty `group_members` means the group has no members configured in MA. A stop trigger (id `stop`) pauses and then clears the MA queue.

## Gotchas

- Renaming an input key is a breaking change: existing automations lose that input's value and must be reconfigured. Event names and event data are public API (dashboard scripts, Node-RED, REST, `examples/audiobook.sh`). Both were renamed to English once (see README "Upgrading"); avoid further renames.

- Every automation made from a blueprint receives the public events. The owner once had 8 "Hörbuch vorlesen" automations (created by saving the blueprint again after each re-import), so one event started the book 8 times. Voice triggers don't show this, because Assist routes a sentence to one automation only.

## Ideas / backlog

- Reminders that survive HA restarts (store due time, e.g. in an `input_datetime` helper or via a timestamp trigger), at the cost of needing helpers.
- Clock times in words ("Viertel nach zwei", "halb drei").
- "Welche Erinnerungen habe ich?" / "Lösche die Erinnerung an …".
- A Swiss German friendly response style, optional.
