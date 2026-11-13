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

A blueprint cannot call an HTTP API on its own, so you add a `rest_command` to `configuration.yaml` once. The blueprint expects it under the name `abs_hoerbuecher`.

1. In Audiobookshelf, open **Settings → Users**, click your user and copy the API token. On newer versions you can also create an API key under **Settings → API Keys**.
2. Add the token to `secrets.yaml`, including the word `Bearer`:

   ```yaml
   abs_token: "Bearer YOUR_TOKEN"
   ```

3. Add this to `configuration.yaml` and adjust the address:

   ```yaml
   rest_command:
     abs_hoerbuecher:
       url: "http://audiobookshelf.example.lan:13378/api/me/items-in-progress"
       method: GET
       headers:
         Authorization: !secret abs_token
   ```

4. Restart Home Assistant (or reload "REST commands" under Developer tools → YAML).
5. Test it under **Developer tools → Actions**: run `rest_command.abs_hoerbuecher` and check that the response lists your book under `content.libraryItems`.

The token belongs to one Audiobookshelf user. Use the user whose progress you want to follow.

Playback starts with `enqueue: replace`, so an old Music Assistant queue is replaced. Stopping pauses playback, waits 2 seconds so Music Assistant can report the position to Audiobookshelf, then clears the queue. The book can then continue on another device without an outdated position on the Voice PE. The sleep timer can start this automation through the `hoerbuch_vorlesen` event (see below).

**Which player?** Same as the sleep timer: without fixed players, the blueprint uses the Music Assistant player in the area of the voice device that heard the command.

Music Assistant creates its own device for each player, separate from the Voice PE. That device usually has no area. Assign it to the same area as the Voice PE under **Settings → Devices & services → Music Assistant**. If no Music Assistant player is in the area, the blueprint falls back to one whose name contains the Voice PE's name. Groups are skipped in this fallback.

**Inputs**

| Input        | Default | Description                                                                 |
| ------------ | ------- | --------------------------------------------------------------------------- |
| Feste Player | empty   | Music Assistant players to always use. Empty = the player in the device's area |

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

**Together with "Hörbuch vorlesen".** If you turn on "Hörbuch starten, wenn nichts läuft" and nothing is playing when you set the timer, the sleep timer fires the `hoerbuch_vorlesen` event. The "Hörbuch vorlesen" automation then starts the current book. If that fails (for example, no book in progress), the error is announced on the voice device. This needs an automation created from the "Hörbuch vorlesen" blueprint.

**Clearing the queue.** After pausing, the sleep timer clears the player's Music Assistant queue (input "Warteschlange leeren", on by default). If you then keep listening on another device, the Voice PE does not hold on to an outdated position. The next "Lies mir weiter vor" fetches the current position from Audiobookshelf.

**Inputs**

| Input         | Default | Description                                                      |
| ------------- | ------- | ---------------------------------------------------------------- |
| Feste Player  | empty   | Media players to always use. Empty = players in the device's area |
| Standarddauer | 30 min  | Duration when none is given                                      |
| Ausblendzeit  | 60 s    | How long the volume fades out before pausing (0 = no fade)       |
| Hörbuch starten, wenn nichts läuft | off | Start the current book via "Hörbuch vorlesen" if nothing plays |
| Warteschlange leeren | on | Clear the Music Assistant queue after pausing |

**Requirements**

- A German Assist pipeline with free-text speech-to-text (e.g. Whisper), same as for the reminder.
- Media players that support `volume_set` and `media_pause`, such as Music Assistant players.

**Limitations**

- Running timers are lost if Home Assistant restarts.
- Cancelling during the fade-out does not stop the fade.

## License

[MIT](LICENSE)
