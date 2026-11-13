# Project context

Public repository of Home Assistant blueprints, developed together with Claude. This file carries the context from the original chat so work can continue in an IDE. Read `docs/history.md` for the full background.

## Goal

Share fully local, German-language voice automations for Home Assistant Assist and Voice PE devices as importable blueprints.

## Conventions

- Blueprints live in `blueprints/<domain>/<name>.yaml` (domain = `automation` or `script`).
- User-facing texts, sentences, variable names and comments in the blueprints are German. README and repo docs are English.
- One blueprint should be self-contained (single import). Prefer patterns that avoid needing a separate script (see "event self-trigger" below).
- Use current HA syntax: `triggers:` / `trigger:`, `actions:` / `action:`, `conditions:`.
- Keep `source_url` in each blueprint pointing at its raw location in this repo, so users can re-import updates.
- Avoid backslashes in Jinja regexes inside YAML block scalars; use character classes like `[ ]`, `[0-9]`, `[.]` instead.
- Quote or use block scalars (`>`) for any text containing `": "`; an unquoted colon breaks the import (this bug happened once).
- No secrets, tokens, IPs or personal data in this repo.
- Run `python3 scripts/validate.py` after changing a blueprint. It only checks YAML structure; real testing happens in HA (import the blueprint, then use the pipeline debug view).

## Patterns in use

- **Conversation trigger with wildcards**: `"Erinnere mich in {dauer} an {sache}"`, values in `trigger.slots`. Use `trigger.slots.get('x', '')` because not every trigger has every slot.
- **Event self-trigger**: the automation (`mode: parallel`) fires a custom event, and a second trigger in the same automation catches it and does the long `delay`. This returns the conversation response immediately while waiting in the background. Filter on `trigger.event.data.quelle == this.entity_id` so multiple instances don't react to each other.
- **Announce** with `assist_satellite.announce`, targeting `trigger.device_id` (the device that heard the command) or a configured list of satellites.

## Status

- `blueprints/automation/sprach_erinnerung.yaml`: working in the owner's setup (duration in seconds/minutes/hours and combinations, clock time "um HH:MM"). `source_url` and the README import badge point at github.com/oxivanisher/oxivanisher-ha-blueprints.

- `blueprints/automation/hoerbuch_schlaftimer.yaml`: sleep timer for Music Assistant / audiobooks. Not yet tested in HA. It uses the event self-trigger pattern. The internal `hoerbuch_schlaftimer` event carries `quelle`; external control (dashboard, Node-RED, REST API) uses the public `hoerbuch_schlaftimer_stellen` event (`aktion` `start`/`abbrechen`, optional `minuten`, `player`, `device`), handled by the same code as the voice triggers. Without player and fixed players, it uses the currently playing MA players (members of a playing group left out). Like stopping, the timer is group-aware: a player that belongs to a playing MA group is replaced by that group, so all rooms fade and stop together. The background run waits in a `wait_for_trigger` loop, so a newer timer or "abbrechen" for an overlapping player ends it. If no players are configured, it picks the player by the area of `trigger.device_id`. If nothing is playing, it can optionally start the book through the `hoerbuch_vorlesen` event. After pausing, it clears the MA queue (`media_player.clear_playlist`), so a stale position does not stick when the book is continued on another device.

- `blueprints/automation/hoerbuch_vorlesen.yaml`: plays the most recent in-progress Audiobookshelf book through Music Assistant (`play_media` by title). Not yet tested in HA. It needs a user-defined `rest_command.abs_hoerbuecher` (GET `/api/me/items-in-progress`, Bearer token in `secrets.yaml`), so it is not fully self-contained. That is unavoidable, because blueprints can't make HTTP calls. Music Assistant's `get_library` `last_played` sort was rejected as unreliable for Audiobookshelf. Besides the voice trigger it listens for a `hoerbuch_vorlesen` event (data: `aktion` `start`/`stopp`/`umschalten`, default `start`; `umschalten` stops if a target player or a group containing it is playing, else starts; optional `player` list, default the fixed players; optional `device`). The sleep timer fires it when nothing is playing, and dashboard scripts use it for start/stop buttons (examples in the README). Errors from event-triggered runs go to a persistent notification, a `hoerbuch_fehler` event (`quelle`, `meldung`) and, if `device` is set, an announcement. Stopping is group-aware: a playing MA group is paused instead of the single speaker. A player counts as a member if it is in the group's `group_members` or has the same `active_queue` as the group. MA sync groups (`mass_player_type: group`) list their members in `group_members` (confirmed in the owner's setup); `active_queue` is only a fallback. An empty `group_members` means the group has no members configured in MA. A stop trigger (id `stopp`) pauses and then clears the MA queue.

## Gotchas

- Every automation made from a blueprint receives the public events. The owner once had 8 "Hörbuch vorlesen" automations (created by saving the blueprint again after each re-import), so one event started the book 8 times. Voice triggers don't show this, because Assist routes a sentence to one automation only.

## Ideas / backlog

- Reminders that survive HA restarts (store due time, e.g. in an `input_datetime` helper or via a timestamp trigger), at the cost of needing helpers.
- Clock times in words ("Viertel nach zwei", "halb drei").
- "Welche Erinnerungen habe ich?" / "Lösche die Erinnerung an …".
- A Swiss German friendly response style, optional.
