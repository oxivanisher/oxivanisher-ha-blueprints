# Home Assistant Blueprints

Blueprints for Home Assistant Assist, focused on fully local, German-language voice control with Home Assistant Voice PE devices.

## Sprach-Erinnerung (Deutsch)

Voice reminders, like "remind me…" on Alexa, but fully local.

[![Open your Home Assistant instance and show the blueprint import dialog.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Foxivanisher%2Foxivanisher-ha-blueprints%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fsprach_erinnerung.yaml)

**Examples**

- "Erinnere mich in 45 Sekunden an die Eier"
- "Erinnere mich in 10 Minuten an den Tee"
- "Erinnere mich in einer halben Stunde an den Ofen"
- "Erinnere mich in 1 Stunde und 30 Minuten an die Wäsche"
- "Erinnere mich um 14:15 an die Wäsche" (also "14.15 Uhr", "14 Uhr 15", "14 Uhr")

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
