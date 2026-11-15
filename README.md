# Home Assistant Blueprints

Blueprints for Home Assistant Assist, focused on fully local, German-language voice control with Home Assistant Voice PE devices.

## Importing

There are three ways to get a blueprint into Home Assistant. All of them end up in the same place: a file under `/config/blueprints/`.

### Option 1: Import button

Each blueprint has an import button. It goes through [my.home-assistant.io](https://my.home-assistant.io/), which forwards your browser to your own Home Assistant and opens the import dialog there. This needs:

- The [My Home Assistant](https://www.home-assistant.io/integrations/my/) integration, which is part of `default_config:`. Without `default_config:`, add `my:` to `configuration.yaml` and restart.
- The address of your Home Assistant saved on my.home-assistant.io (pencil icon on that page), as you type it in your browser, e.g. `https://ha.example.lan:8123`.

If the button opens Home Assistant but no import dialog appears, use option 2 or 3.

### Option 2: Import by URL (recommended if the button does not work)

1. In Home Assistant, go to **Settings → Automations & scenes → Blueprints**.
2. Click **Import blueprint** (bottom right).
3. Paste the blueprint's GitHub URL, e.g. `https://github.com/oxivanisher/oxivanisher-ha-blueprints/blob/main/blueprints/automation/sprach_erinnerung.yaml`.
4. Click **Preview**, then **Import blueprint**.

Home Assistant downloads the file itself, so the Home Assistant host needs outbound internet access to `github.com` (check this if it sits in a restricted VLAN). Because the blueprint has a `source_url`, you can later update it from the blueprint's ⋮ menu → **Re-import blueprint**.

### Option 3: Copy the file

If Home Assistant has no internet access, copy the file yourself:

1. Download the YAML file from this repository.
2. Put it into your Home Assistant config folder at the same relative path, e.g. `/config/blueprints/automation/oxivanisher/sprach_erinnerung.yaml` (via the File editor or Samba add-on, SSH, or your Docker volume). Create the folders if they do not exist.
3. Go to **Developer tools → YAML** and click **Automations** under "YAML configuration reloading", or restart Home Assistant.
4. The blueprint now shows up under **Settings → Automations & scenes → Blueprints**.

Updates work the same way: replace the file and reload.

### After importing: create an automation

A blueprint on its own does nothing. Importing only makes it available as a template:

1. Go to **Settings → Automations & scenes → Blueprints**.
2. Click the blueprint, fill in the inputs, and click **Save**.

Only then are the voice commands active. Updating the blueprint later (re-import or replacing the file) updates every automation created from it.

## Sprach-Erinnerung (Deutsch)

Voice reminders, like "remind me…" on Alexa, but fully local.

[![Open your Home Assistant instance and show the blueprint import dialog.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Foxivanisher%2Foxivanisher-ha-blueprints%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fsprach_erinnerung.yaml)

**Examples**

- "Erinnere mich in 45 Sekunden an die Eier"
- "Erinnere mich in 10 Minuten an den Tee"
- "Erinnere mich in einer halben Stunde an den Ofen"
- "Erinnere mich in 1 Stunde und 30 Minuten an die Wäsche"
- "Erinnere mich um 14:15 an die Wäsche" (also "14.15 Uhr", "14 Uhr 15", "14 Uhr")

"Erinner mich" and "Erinnern mich" (common speech-to-text results for Swiss German) and an optional "bitte" ("Erinnere mich bitte in …") are accepted too.

The assistant confirms right away. When the time is up, the reminder is announced on the device that heard the command, or on fixed devices you choose.

**Inputs**

| Input               | Default       | Description                                                                       |
| ------------------- | ------------- | --------------------------------------------------------------------------------- |
| Ansage-Präfix       | `Erinnerung:` | Text spoken before the reminder                                                   |
| Feste Ansage-Geräte | empty         | Assist satellites that always announce. Empty = the device that heard the command |

**Requirements**

- A German Assist pipeline (any speech-to-text that outputs free text, e.g. Whisper. Speech-to-phrase cannot capture free-form wildcards).
- An Assist satellite that supports `assist_satellite.announce`, such as the Home Assistant Voice PE.

**Limitations**

- Pending reminders are lost if Home Assistant restarts.
- Clock times in words ("Viertel nach zwei") are not understood yet; use digits.

**Manual import:** Settings → Automations & scenes → Blueprints → Import blueprint, and paste the URL of `blueprints/automation/sprach_erinnerung.yaml`.

## Hörbuch vorlesen (Deutsch)

Reads your current audiobook aloud, by voice, and picks up where you left off, even if you listened on another device (phone app, web player) in between. Music Assistant's own "last played" sort is unreliable for Audiobookshelf libraries, so this blueprint asks Audiobookshelf directly which book is in progress. It then plays that book through Music Assistant, which resumes at the saved position.

[![Open your Home Assistant instance and show the blueprint import dialog.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Foxivanisher%2Foxivanisher-ha-blueprints%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fhoerbuch_vorlesen.yaml)

**Examples**

- "Lies mir das aktuelle Buch vor" / "Lies mir weiter vor"
- "Spiel mein Hörbuch" / "Spiel mein Hörbuch weiter"
- "Hörbuch weiterhören" / "Hörbuch fortsetzen"
- "Stopp das Hörbuch" / "Hörbuch beenden" / "Hör auf vorzulesen"

**One-time setup: Audiobookshelf API access**

A blueprint cannot call an HTTP API on its own, so you add two general-purpose `rest_command`s to `configuration.yaml` once. The blueprints pass the API path (and for writes the data) to them, so the address and token are defined in one place.

1. In Audiobookshelf, open **Settings → Users**, click your user and copy the API token. On newer versions you can also create an API key under **Settings → API Keys**.
2. Add the token and the API address to `secrets.yaml`. Keep the word `Bearer` and the `{{ path }}` at the end of the address:

   ```yaml
   abs_token: "Bearer YOUR_TOKEN"
   abs_api_url: "http://audiobookshelf.example.lan:13378/api/{{ path }}"
   ```

3. Add this to `configuration.yaml`:

   ```yaml
   rest_command:
     audiobookshelf_get:
       url: !secret abs_api_url
       method: GET
       headers: &abs_headers
         Authorization: !secret abs_token
         Content-Type: application/json
     audiobookshelf_patch:
       url: !secret abs_api_url
       method: PATCH
       headers: *abs_headers
       payload: "{{ payload | to_json }}"
   ```

   `audiobookshelf_get` is needed for playback. `audiobookshelf_patch` is only needed for "Zurückspulen" (see below), but it doesn't hurt to add it right away.

4. Restart Home Assistant (or reload "REST commands" under Developer tools → YAML).
5. Test it under **Developer tools → Actions**: run `rest_command.audiobookshelf_get` with the data `path: me/items-in-progress` and check that the response lists your book under `content.libraryItems`.

The token belongs to one Audiobookshelf user. Use the user whose progress you want to follow.

**Optional: rewind on stop.** To hear the last part again when you continue, add `audiobookshelf_patch` as above and set the input "Zurückspulen" (e.g. 30 s) in both audiobook automations. It is off (0) by default, because a missing `rest_command` stops the automation with an error. Leave it at 0 if you don't add `audiobookshelf_patch`.

How it works: before pausing, the blueprint reads the book's position from Audiobookshelf. Music Assistant reports it there about every 30 seconds, so it is never ahead of what you heard. The blueprint adds the time since that report (at most 30 seconds) to estimate where you are. After stopping, it sets the position in Audiobookshelf to that estimate minus the rewind time. It does not seek in Music Assistant: after a seek, Music Assistant reported a position that was too far ahead, so the book skipped forward on the next start. If Audiobookshelf returns no position, the stop still works and a notification explains why there was no rewind.

Playback starts with `enqueue: replace`, so an old Music Assistant queue is replaced. Stopping pauses playback, waits 2 seconds so Music Assistant can report the position to Audiobookshelf, then clears the queue. The book can then continue on another device without an outdated position on the Voice PE. The sleep timer can start this automation through the `audiobook_play` event (see below).

**Which player?** Same as the sleep timer: without fixed players, the blueprint uses the Music Assistant player in the area of the voice device that heard the command.

Music Assistant creates its own device for each player, separate from the Voice PE. That device usually has no area. Assign it to the same area as the Voice PE under **Settings → Devices & services → Music Assistant**. If no Music Assistant player is in the area, the blueprint falls back to one whose name contains the Voice PE's name. Groups are skipped in this fallback.

**Inputs**

| Input        | Default | Description                                                                 |
| ------------ | ------- | --------------------------------------------------------------------------- |
| Feste Player | empty   | Music Assistant players to always use. Empty = the player in the device's area |
| Zurückspulen | 0 s     | Rewind this far on stop, so the last part is repeated when you continue. Needs the two extra rest_commands (0 = off) |
| Start-Lautstärke | 0 % | Volume to set when the book starts (0 = leave unchanged) |

**Start volume.** With "Start-Lautstärke" set, the volume is set before playback starts and once more as soon as the player plays (a Music Assistant group that is off may ignore the first one). The voice response can then take a moment longer. For a group, Music Assistant scales the rooms relative to each other, so 30 % on the group does not mean 30 % in every room.

**Speaker groups.** To listen in every room at once, create a group player in Music Assistant and set it as "Feste Player". Starting then plays on the group. Stopping also handles groups: if a playing Music Assistant group contains the target player, the whole group is paused, not just one speaker.

**Dashboard buttons.** The automation also listens for the `audiobook_play` event, with this data:

| Field    | Default        | Description                                    |
| -------- | -------------- | ---------------------------------------------- |
| `action` | `start`        | `start`, `stop` or `toggle` (toggle: stop if the player or its group is playing, otherwise start) |
| `players` | "Feste Player" | List of Music Assistant players to use instead |
| `volume` | "Start-Lautstärke" | Volume in percent when starting (0 = use the input) |

A dashboard cannot fire events directly, so add these scripts (Settings → Automations & scenes → Scripts, or `scripts.yaml`):

```yaml
audiobook_start:
  alias: Hörbuch starten
  icon: mdi:book-play
  sequence:
    - event: audiobook_play
      event_data:
        action: start

audiobook_stop:
  alias: Hörbuch stoppen
  icon: mdi:book-cancel
  sequence:
    - event: audiobook_play
      event_data:
        action: stop

# Optional: one button for both
audiobook_toggle:
  alias: Hörbuch an/aus
  icon: mdi:book-music
  sequence:
    - event: audiobook_play
      event_data:
        action: toggle
```

Without `players`, the automation's "Feste Player" are used (e.g. your group). To target another player, add `players: [media_player.kueche]` to `event_data`. Then add the scripts to a dashboard, e.g. as a button card:

```yaml
type: button
entity: script.audiobook_toggle
tap_action:
  action: perform-action
  perform_action: script.audiobook_toggle
```

Without "Feste Player" and without `players` in the event, the automation has no voice device to pick a player from. Nothing plays, and the error is reported (see [Errors](#errors-from-buttons-node-red-and-the-api)). For Node-RED and the REST API, see [Control from Node-RED and the REST API](#control-from-node-red-and-the-rest-api).

**Limitations**

- Music Assistant looks up the book by its title. If another provider (e.g. Spotify) has a book with the same title, Music Assistant may pick that one instead.
- Podcasts in progress are ignored. Only books are resumed.

## Hörbuch-Schlaftimer (Deutsch)

A voice sleep timer for audiobooks (e.g. Audiobookshelf via Music Assistant). It works with any media player. Shortly before the timer ends, the volume fades out. Then playback pauses and the original volume is restored for next time.

[![Open your Home Assistant instance and show the blueprint import dialog.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Foxivanisher%2Foxivanisher-ha-blueprints%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fhoerbuch_schlaftimer.yaml)

**Examples**

- "Schlaftimer 20 Minuten" (a number without a unit counts as minutes)
- "Stell einen Schlaftimer auf eine halbe Stunde"
- "Stoppe das Hörbuch in 45 Minuten" / "Hörbuch in 1 Stunde stoppen"
- "Schlaftimer starten" (uses the default duration)
- "Lies mir für 30 Minuten vor" / "Spiel mein Hörbuch für eine Stunde"
- "Schlaftimer abbrechen" / "Brich den Schlaftimer ab"

"Sleeptimer", "Sleep Timer" and "Einschlaftimer" also work. A new timer replaces the one already running for the same player.

**Which player?** If you leave "Feste Player" empty, the blueprint takes the media players in the same area as the voice device that heard the command. Music Assistant players are preferred, and among those the ones currently playing. So assign each Voice PE and its Music Assistant player to the same area. Without that, the same name-based fallback as in "Hörbuch vorlesen" applies.

**Together with "Hörbuch vorlesen".** If you turn on "Hörbuch starten, wenn nichts läuft" and nothing is playing when you set the timer, the sleep timer fires the `audiobook_play` event. The "Hörbuch vorlesen" automation then starts the current book. If that fails (for example, no book in progress), the error is announced on the voice device. This needs an automation created from the "Hörbuch vorlesen" blueprint.

**Clearing the queue.** After pausing, the sleep timer clears the player's Music Assistant queue (input "Warteschlange leeren", on by default). If you then keep listening on another device, the Voice PE does not hold on to an outdated position. The next "Lies mir weiter vor" fetches the current position from Audiobookshelf.

**Speaker groups.** If the chosen player belongs to a Music Assistant group that is currently playing, the timer acts on the whole group. For example, if the book plays in all rooms and you set the timer by voice in the bedroom, all rooms fade out and stop together. You can also set your group as "Feste Player" in the sleep timer automation. The two automations have separate inputs, so a group set in "Hörbuch vorlesen" does not carry over.

**Dashboard buttons.** The sleep timer listens for the `audiobook_sleep_timer` event:

| Field     | Default                 | Description                                    |
| --------- | ----------------------- | ---------------------------------------------- |
| `action`  | `start`                 | `start` or `cancel`                            |
| `minutes` | "Standarddauer"         | Timer length in minutes                        |
| `players` | see below               | List of media players to use instead           |
| `device`  | none                    | Voice device on which errors are also announced |
| `volume`  | "Lautstärke im Schlafmodus" | Sleep volume in percent for this call |

Which player is used: `players` from the event, otherwise "Feste Player". If neither is set, the timer uses the Music Assistant players that are currently playing (members of a playing group are left out, so only the group is faded). "Hörbuch starten, wenn nichts läuft" and "Warteschlange leeren" work as with voice commands.

```yaml
audiobook_sleep_timer:
  alias: Hörbuch-Schlaftimer
  icon: mdi:sleep
  sequence:
    - event: audiobook_sleep_timer
      event_data:
        action: start    # add "minutes: 45" for a different length

audiobook_sleep_timer_cancel:
  alias: Schlaftimer abbrechen
  icon: mdi:sleep-off
  sequence:
    - event: audiobook_sleep_timer
      event_data:
        action: cancel
```

**Inputs**

| Input         | Default | Description                                                      |
| ------------- | ------- | ---------------------------------------------------------------- |
| Feste Player  | empty   | Media players to always use. Empty = players in the device's area |
| Standarddauer | 30 min  | Duration when none is given                                      |
| Ausblendzeit  | 60 s    | How long the volume fades out before pausing (0 = no fade)       |
| Hörbuch starten, wenn nichts läuft | off | Start the current book via "Hörbuch vorlesen" if nothing plays |
| Warteschlange leeren | on | Clear the Music Assistant queue after pausing |
| Zurückspulen | 0 s | Rewind this far when the timer pauses. Same Audiobookshelf mechanism and rest_commands as "Hörbuch vorlesen" (0 = off) |
| Lautstärke im Schlafmodus | 0 % | Lower to this volume when the timer is set (never raises it); a book started by the timer starts at this volume (0 = leave unchanged) |

**Requirements**

- A German Assist pipeline with free-text speech-to-text (e.g. Whisper), same as for the reminder.
- Media players that support `volume_set` and `media_pause`, such as Music Assistant players.

**Limitations**

- Running timers are lost if Home Assistant restarts.
- Cancelling during the fade-out does not stop the fade.

## Control from Node-RED and the REST API

Both audiobook blueprints are controlled by Home Assistant events, so anything that can fire an event can use them:

| Event                   | Data                                                        | Blueprint           |
| ----------------------- | ----------------------------------------------------------- | ------------------- |
| `audiobook_play`        | `action` (`start`/`stop`/`toggle`), `players`, `device`, `volume`     | Hörbuch vorlesen    |
| `audiobook_sleep_timer` | `action` (`start`/`cancel`), `minutes`, `players`, `device`, `volume` | Hörbuch-Schlaftimer |

All fields are optional. See the blueprint sections above for the defaults.

**Create only one automation per blueprint.** Every automation made from a blueprint reacts to these events. With several "Hörbuch vorlesen" automations, one event starts the book several times. Voice commands hide this, because Assist hands a sentence to only one automation. To update a blueprint, re-import it; existing automations pick up the new version, so don't create a new one afterwards. To find duplicates, open the blueprint's ⋮ menu → **Show automations using this blueprint**.

**Node-RED** (with `node-red-contrib-home-assistant-websocket`): use a **Fire Event** node. Set the event to e.g. `audiobook_play` with data `{"action": "toggle"}`, or `audiobook_sleep_timer` with `{"action": "start", "minutes": 20}`. Alternatively, call the dashboard scripts with an **Action** node.

**REST API:** create a long-lived access token in Home Assistant (your profile → **Security** → **Long-lived access tokens**). Then POST the event data to `/api/events/<event>`:

```bash
TOKEN="your long-lived token"
HA="http://homeassistant.example.lan:8123"

# Start the book
curl -X POST "$HA/api/events/audiobook_play" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"action": "start"}'

# Stop the book
curl -X POST "$HA/api/events/audiobook_play" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"action": "stop"}'

# Toggle: stop if playing, otherwise start
curl -X POST "$HA/api/events/audiobook_play" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"action": "toggle"}'

# Sleep timer with the default length, or with 20 minutes
curl -X POST "$HA/api/events/audiobook_sleep_timer" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{}'
curl -X POST "$HA/api/events/audiobook_sleep_timer" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"minutes": 20}'
```

**Shell script:** [examples/audiobook.sh](examples/audiobook.sh) wraps these calls. Set `HA_URL` and `HA_TOKEN` as environment variables or in `~/.config/audiobook.env`, then run:

```bash
audiobook.sh start | stop | toggle
audiobook.sh start 30       # start at 30 % volume
audiobook.sh sleep          # default length
audiobook.sh sleep 20       # 20 minutes
audiobook.sh sleep cancel
audiobook.sh vol up | down   # one volume step
audiobook.sh vol 40          # set volume to 40 %
```

Volume is a regular Home Assistant action, not a blueprint event, so `vol` needs to know the player: set `HA_VOLUME_PLAYER=media_player.wohnung` (falls back to `HA_PLAYER`). For a Music Assistant group, Music Assistant changes all members relative to each other. The step size of `up`/`down` is set by the player. Without the script, call the action directly:

```bash
curl -X POST "$HA/api/services/media_player/volume_up" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"entity_id": "media_player.wohnung"}'
```

Use `volume_down`, or `volume_set` with `"volume_level": 0.4`, the same way.

Optionally set `HA_PLAYER=media_player.wohnung` (comma-separated for several) to override the automations' "Feste Player". The script exits with an error if Home Assistant rejects the request.

The API answers right away with `{"message": "Event ... fired."}`, which only means that Home Assistant received the event. Whether something actually plays is reported as described below. The token gives full access to Home Assistant, so keep it secret.

### Errors from buttons, Node-RED and the API

Voice commands answer by voice. Events have nobody to answer to, so problems are reported in three ways:

- A **notification** in Home Assistant (bell icon in the sidebar). A newer message replaces the older one.
- A `audiobook_error` **event** with `source` (the automation) and `message` (the text). Listen for it in Node-RED, e.g. to send a push message.
- An **announcement** on the voice device, if the event contained `device`.

Reported errors include: no player found, Audiobookshelf not answering, no book in progress, an invalid sleep timer length, and a sleep timer set while nothing plays (when "Hörbuch starten, wenn nichts läuft" is off).

## Upgrading from earlier versions

Internal names (inputs, events, event data) were renamed to English. User-facing texts and voice commands are still German. After re-importing the blueprints:

1. **Inputs:** open each automation made from these blueprints and set its inputs again. The old values are not carried over, because the input keys changed.
2. **rest_command:** replace the old command(s) with `audiobookshelf_get` and `audiobookshelf_patch` as described in the setup above, and reload REST commands.
3. **Scripts, Node-RED, API calls:** update events and event data.

| Old                                  | New                                      |
| ------------------------------------ | ---------------------------------------- |
| event `hoerbuch_vorlesen`            | `audiobook_play`                         |
| event `hoerbuch_schlaftimer_stellen` | `audiobook_sleep_timer`                  |
| event `hoerbuch_fehler`              | `audiobook_error`                        |
| `aktion`                             | `action`                                 |
| `stopp` / `umschalten` / `abbrechen` | `stop` / `toggle` / `cancel`             |
| `minuten`                            | `minutes`                                |
| `player`                             | `players`                                |
| `quelle` / `meldung` (error event)   | `source` / `message`                     |
| `examples/hoerbuch.sh`, `hoerbuch.env` | `examples/audiobook.sh`, `audiobook.env` |
| rest_command `abs_hoerbuecher`, later `audiobookshelf_in_progress`, `audiobookshelf_get_progress`, `audiobookshelf_set_progress` | `audiobookshelf_get` and `audiobookshelf_patch` (with `path`, `payload`) |

## License

[MIT](LICENSE)
