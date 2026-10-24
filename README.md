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

## License

[MIT](LICENSE)
