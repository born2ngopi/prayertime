# 🕌 Prayer Time — born2ngopi.prayertime

Islamic prayer times widget for the [Omarchy](https://github.com/anomalyco/omarchy) bar.
Shows the **next prayer on the bar** (`Maghrib: 17:51`), opens a centered panel with the
full daily schedule + Hijri date, lets you pick a calculation method and location, and
sends a desktop notification when prayer time arrives.

## Features

- **Bar widget** — always shows the *next* prayer and its time (skips Imsak/Sunrise).
- **Panel popup** — full schedule for today, Hijri date, the next prayer highlighted.
- **Calculation method dropdown** — 23 methods (strings displayed, integer values stored).
  Default: `20` (KEMENAG, Indonesia).
- **Custom coordinates** — type your Lat/Long in the panel and hit *Save & Refresh*
  (Enter also submits). Great for users outside Indonesia.
- **Desktop notifications** — fires within the 5 minutes before each prayer
  (deduplicated per prayer).
- **Multi-language UI** — English, Bahasa Indonesia, and العربية (RTL). Prayer names,
  panel labels, hijri date, and notifications all translate live.
- **Persistent settings** — your method, coordinates and language survive shell reloads
  (see [Configuration](#configuration)).
- **Right-click the bar widget** to force-refresh the schedule.

## Install

```bash
# enable the plugin (registry id may differ from the folder name)
omarchy plugin enable born2ngopi.prayertime --section right

# optional: move it to the center section, next to the clock
omarchy bar move born2ngopi.prayertime --section center

# restart the shell to load it
omarchy restart shell
```

> Requires a **network connection** — times are fetched from the
> [Aladhan Prayer Times API](https://aladhan.com/prayer-times-api).

## Usage

| Action | Result |
| --- | --- |
| Left-click bar widget | opens the centered panel |
| Right-click bar widget | re-fetches today's times |
| Panel → *Calculation Method* | pick your authority; times refresh instantly |
| Panel → *Language* | switch UI between English / Bahasa Indonesia / العربية |
| Panel → *Save & Refresh* | apply new Lat/Long (Enter also works) |

## Configuration

Settings are persisted to **`~/.local/state/omarchy/prayertime.json`** (created
automatically on first run):

```json
{
  "settings": {
    "latitude": "-6.2088",
    "longitude": "106.8456",
    "calcMethod": 20,
    "language": "id"
  }
}
```

The file is watched — you can edit it live while the shell runs, or just use the
panel UI. Everything survives a shell restart.

### Language

Available languages: `en`, `id`, `ar`. If no language is set, it defaults to the
system locale when supported, otherwise English. Translations live in the
[`i18n/`](i18n/) folder as JSON key-maps (keys like `panel.title`, `prayer.Fajr`,
`notify.body`); the active file is reloaded and applied live when you switch
language, with English always used as a fallback for missing keys.

### Calculation methods

| Method | Name |
| --- | --- |
| 0 | Jafari / Shia Ithna-Ashari |
| 1 | University of Islamic Sciences, Karachi |
| 2 | Islamic Society of North America |
| 3 | Muslim World League |
| 4 | Umm Al-Qura University, Makkah |
| 5 | Egyptian General Authority of Survey |
| 7 | Institute of Geophysics, University of Tehran |
| 8 | Gulf Region |
| 9 | Kuwait |
| 10 | Qatar |
| 11 | Majlis Ugama Islam Singapura, Singapore |
| 12 | Union Organization islamic de France |
| 13 | Diyanet İşleri Başkanlığı, Turkey |
| 14 | Spiritual Administration of Muslims of Russia |
| 15 | Moonsighting Committee Worldwide |
| 16 | Dubai (experimental) |
| 17 | Jabatan Kemajuan Islam Malaysia (JAKIM) |
| 18 | Tunisia |
| 19 | Algeria |
| 20 | KEMENAG - Kementerian Agama Republik Indonesia |
| 21 | Morocco |
| 22 | Comunidade Islamica de Lisboa |
| 23 | Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan |

## File structure

```
born2ngopi.playertime/
├── manifest.json     # registry: bar-widget + overlay + service entry points
├── Service.qml       # API fetch, next-prayer logic, notifications, i18n, persistence
├── Panel.qml         # bar widget (qs.Ui.BarWidget) — shows "Next: HH:MM"
├── Popup.qml         # centered panel: schedule, method + language dropdowns, coordinates
├── Notification.qml  # overlay shown on summon (qs.Ui overlay contract)
└── i18n/
    ├── en.json       # English translations (fallback)
    ├── id.json       # Bahasa Indonesia translations
    └── ar.json       # العربية translations
```

## Troubleshooting

After editing QML files, hot-reload may keep stale compiled code. Fix:

```bash
rm -rf ~/.cache/quickshell/qmlcache ~/.cache/quickshell/qtpipelinecache-*
omarchy restart shell
```

Watch the logs for errors:

```bash
journalctl --user -u omarchy-shell -f
```

## Credits

- Prayer times data: [Aladhan API](https://aladhan.com/prayer-times-api)
- Follows the Omarchy shell/panel/overlay contracts (`qs.Ui.*` components).