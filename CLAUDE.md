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

- `blueprints/automation/hoerbuch_schlaftimer.yaml`: sleep timer for Music Assistant / audiobooks. Not yet tested in HA. It uses the event self-trigger pattern. The background run waits in a `wait_for_trigger` loop, so a newer timer or "abbrechen" for an overlapping player ends it. If no players are configured, it picks the player by the area of `trigger.device_id`. If nothing is playing, it can optionally start the book through the `hoerbuch_vorlesen` event. After pausing, it clears the MA queue (`media_player.clear_playlist`), so a stale position does not stick when the book is continued on another device.

- `blueprints/automation/hoerbuch_vorlesen.yaml`: plays the most recent in-progress Audiobookshelf book through Music Assistant (`play_media` by title). Not yet tested in HA. It needs a user-defined `rest_command.abs_hoerbuecher` (GET `/api/me/items-in-progress`, Bearer token in `secrets.yaml`), so it is not fully self-contained. That is unavoidable, because blueprints can't make HTTP calls. Music Assistant's `get_library` `last_played` sort was rejected as unreliable for Audiobookshelf. Besides the voice trigger it listens for a `hoerbuch_vorlesen` event (data: `player` list, optional `device`), which the sleep timer fires when nothing is playing. A stop trigger (id `stopp`) pauses and then clears the MA queue.

## Ideas / backlog

- Reminders that survive HA restarts (store due time, e.g. in an `input_datetime` helper or via a timestamp trigger), at the cost of needing helpers.
- Clock times in words ("Viertel nach zwei", "halb drei").
- "Welche Erinnerungen habe ich?" / "Lösche die Erinnerung an …".
- A Swiss German friendly response style, optional.
