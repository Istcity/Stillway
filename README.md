# Stillway

Stillway is an offline, dark-only ambient companion for iPhone. It watches where you are and what you are doing, then starts the right sound — commute, focus, reset, or sleep — without asking you to pick a track.

> Sen sadece yaşa. Geri kalanı biz anlıyoruz.

## Features

- Context-aware themes (commute, focus, sleep, reset, walking, deep work)
- AVAudioEngine playback with Journey Arc volume shaping
- Transit geofencing from an on-device station database
- CLVisit place learning and optional auto-start (Pro)
- Sleep detection (home + hour + phone orientation)
- Core Haptics box-breathing guide (Pro / Taptic Engine)
- Dynamic Island Live Activity, Lock Screen and Home Screen widgets
- Turkish, Japanese, English, French — language changes apply instantly
- No account, no analytics, no ads, no backend

## Requirements

- Xcode 16+
- iOS 17.0+
- macOS 14+
- Apple Developer Team `R9VURFRPRC` (same team as Lokus / FLOW)
- Physical device for geofence, motion, and Dynamic Island

## Signing

Same paid team as Lokus / FLOW. The App Store Connect app is already named **Stillway** — do not create a second one.

| | |
|---|---|
| Team | `R9VURFRPRC` |
| App bundle ID | `com.sinannergiz.stillway` |
| Widget bundle ID | `com.sinannergiz.stillway.widget` |
| App Group | `group.com.sinannergiz.stillway` |
| Pro IAP | `com.sinannergiz.stillway.pro` |

Automatic signing is on. Home-screen name stays **Stillway**.

## Setup

1. `git pull` then open `Stillway.xcodeproj`.
2. Scheme **Stillway**, destination an iPhone simulator or your device.
3. Signing & Capabilities → Team should already be **R9VURFRPRC** on **Stillway** and **StillwayWidgets**.
4. Run (`⌘R`).

## TestFlight / App Store

Do **not** click **My Apps → + → New App**. The name `Stillway` is already used in this account. Open the existing Stillway record and upload to it.

1. [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **Stillway**
2. App Information → Bundle ID must be **`com.sinannergiz.stillway`**
3. If that Stillway row is empty / wrong and you do not need it: remove it, then you may create a new app. Otherwise leave it.
4. In-App Purchase on that same app: non-consumable `com.sinannergiz.stillway.pro`
5. Xcode → **Product → Archive** → Organizer → **Distribute App** → **App Store Connect** → **Upload** (skip “Create app record”)

If Xcode still tries to create a record: the existing Stillway already is the record. Upload the IPA with Transporter, or Distribute again after confirming the bundle ID matches.

CLI (same pattern as Şantiye Asist):

```bash
xcodebuild -project Stillway.xcodeproj -scheme Stillway \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/Stillway.xcarchive archive

xcodebuild -exportArchive -archivePath build/Stillway.xcarchive \
  -exportPath build/export -exportOptionsPlist ExportOptions.plist
```

## Station database

A sample set ships in `Stillway/Resources/stations.json`. To build the full ~56k-stop file:

```bash
./scripts/download_gtfs.sh
python3 scripts/build_station_db.py
```

Japan (ODPT) and France (IDFM) need a free API key. Set `ODPT_GTFS_URL`, `IDFM_GTFS_URL`, and `IBB_GTFS_URL`. Output schema:

```json
{"id":"...","name":"...","name_en":"...","lat":0.0,"lon":0.0,"country":"JP","city":"Tokyo","type":"METRO","lines":["..."]}
```

## Sound files

Drop seamless-loop `.m4a` files into `Stillway/Resources/Sounds/` using IDs from `Sound.swift`:

`tokyo_metro.m4a`, `shinkansen.m4a`, `paris_metro.m4a`, `istanbul_ferry.m4a`, `tokyo_rain.m4a`, `deep_train.m4a`, `night_cafe.m4a`, `minka_library.m4a`, `kyoto_bamboo.m4a`, `temple_bell.m4a`, `rain_window.m4a`, `night_forest.m4a`

Until those files exist, `AudioEngine` generates distinct procedural beds. For production loops, use prompts in `SUNO_SOUND_PROMPTS.md`.

## App Store checklist

- [ ] 12 field recordings in the bundle
- [ ] Full `stations.json` from GTFS
- [ ] `TrainClassifier.mlmodel` (optional; motion automotive is the fallback)
- [ ] StoreKit product `com.sinannergiz.stillway.pro` live in App Store Connect
- [ ] Privacy nutrition label: location and motion, on-device only
- [ ] Screenshots and metadata in TR / JA / EN / FR
- [ ] TestFlight on a real device (geofence + headphones auto-start)

## Specs

`FREEMIUM_LIFETIME_EXECUTION_PLAN.md` · `PRODUCT_SPEC.md` · `DESIGN_SYSTEM.md` · `BUILD_PLAN.md` · `MISSING_AND_TODOS.md`

## Contributing

Keep the app offline-first. Do not add analytics, accounts, or network calls except StoreKit. Prefer simpler diffs that match the design system over extra abstraction.
