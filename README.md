<div align="center">

# 🎹 Piano Rhythm Master

### A premium mobile rhythm piano game built with Flutter

Tap the falling piano tiles across four lanes. Chain combos, chase accuracy, level up, and climb the ranks — wrapped in a dark, neon, glass-morphic UI with fluid animations.

![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-5CF2C4)
![State](https://img.shields.io/badge/State-Provider-9B5CFF)
![Style](https://img.shields.io/badge/UI-Neon%20%C2%B7%20Glassmorphism-FF4D9D)
![License](https://img.shields.io/badge/License-MIT-FFD76B)

</div>

---

## 📸 Screenshots

<div align="center">

| Splash | Home | Song Selection |
| :---: | :---: | :---: |
| <img src="screenshots/01-splash.png" width="230"/> | <img src="screenshots/02-home.png" width="230"/> | <img src="screenshots/03-song-selection.png" width="230"/> |

| Gameplay | Results | Profile |
| :---: | :---: | :---: |
| <img src="screenshots/04-gameplay.png" width="230"/> | <img src="screenshots/05-result.png" width="230"/> | <img src="screenshots/06-profile.png" width="230"/> |

| Settings |
| :---: |
| <img src="screenshots/07-settings.png" width="230"/> |

</div>

> 📱 Real captures from the app running on an Android emulator (Pixel, API 35).

---

## ✨ Features

- 🎬 **Animated splash** — full-bleed hero artwork with a slow Ken-Burns zoom into the app
- 🏠 **Home hub** — level & coins, pulsing play button in a rotating conic-gradient ring, animated equalizer, quick-play grid
- 🎵 **Song library** — search, category & difficulty filters, favorites, per-song best scores, colored difficulty badges (Easy/Normal/Hard/Expert)
- 🎮 **Piano-Tiles gameplay** — four columns (C·D·E·G); tap the glossy falling tiles anywhere in their column. Comet-tail trails, glow that intensifies as tiles near the bottom, pulsing lane beams, and a **fireworks burst** (the tile shatters into shards + sparks) on every clean hit — with real piano tones
- 🔀 **Two modes** — **Song** (play the whole track; misses just break combo) and **Classic** (one miss ends the run, tiles speed up)
- ✨ **Create songs from text** — type a prompt and a self-hosted [text2midi](https://github.com/amaai-lab/text2midi) endpoint generates a playable chart (MIDI parsed on-device → beat map), saved to your library
- 🏁 **Results** — animated score count-up, rank medallion, star rating, full accuracy breakdown, confetti (or a Game Over banner in Classic), achievement popups
- 👤 **Profile & progression** — XP/levels, coins, songs played, best score/combo/accuracy, unlockable achievements, editable avatar & name
- ⚙️ **Settings** — music & SFX volume, vibration, adjustable tile speed, difficulty, left-hand mode, Classic-mode toggle, account login/logout
- 🏆 **Ranking** — local leaderboard of best runs (architected to become an online leaderboard)
- 🎨 **Design system** — dark theme, neon + gold accents, glassmorphism, animated aurora background with floating particles, gradient titles

---

## 🎯 Gameplay Mechanics

Tap a falling tile anywhere in its column before it reaches the bottom. The **earlier** you catch it, the better the judgment:

| Judgment | When | Base Score |
| :--- | :--- | :--- |
| 🩵 Perfect | caught high in its fall | +100 |
| 💚 Great | caught a bit lower | +70 |
| 💛 Good | caught near the bottom | +40 |
| ❤️ Miss | tile reaches the bottom untapped | 0 |

**Modes** — **Song**: play the full track, a miss/wrong tap only breaks combo & lowers accuracy. **Classic**: one miss or wrong-column tap ends the run, and tiles accelerate the longer you last.

**Combo multiplier** — reward for consecutive hits:

| Combo | Multiplier |
| :--- | :--- |
| 10+ | ×1.2 |
| 50+ | ×1.5 |
| 100+ | ×2.0 |

**Accuracy** is a weighted average of your judgments; **rank** (S/A/B/C/D) and **stars** (0–3) are awarded from final accuracy. Tile fall speed is adjustable in Settings.

---

## 🧱 Tech Stack

| Concern | Choice |
| :--- | :--- |
| Framework | Flutter (Material 3) |
| Language | Dart |
| State management | `provider` |
| Local database | **SQLite** (`sqflite`) — profile, scores, generated songs |
| Settings storage | `shared_preferences` |
| Audio | `audioplayers` (polyphonic pool) |
| Song generation | `http` → self-hosted text2midi endpoint; MIDI parsed on-device |
| Animations | `flutter_animate`, `confetti`, custom painters |
| Fonts | Rubik (bundled) |

---

## 🏛️ Architecture

The app is **local-first but Firebase-ready**. All data flows through a single `GameRepository` interface, so the on-device implementation used today can be swapped for a Firestore-backed one without touching the UI or game logic.

```
UI (screens/widgets)
        │
   Providers  ──►  SettingsProvider · ProfileProvider · GameController (real-time engine)
        │
 GameRepository (interface)  ◄── swap point for Firebase
        │
 SqliteGameRepository  ──►  SQLite (sqflite): profile · scores · custom songs
```

The data models mirror the spec's Firebase collections one-to-one:

| Model | Firebase collection |
| :--- | :--- |
| `UserProfile` | `Users` |
| `Song` / `NoteEvent` | `Songs` (with `beat_map`) |
| `ScoreResult` | `Scores` |

**To go online:** implement `GameRepository` with `cloud_firestore`, register it in `main.dart`, and the rest of the app works unchanged.

### Project structure

```
lib/
├── main.dart                 # bootstrap: prefs, audio, repository, runApp
├── app.dart                  # providers, MaterialApp, page transitions
├── theme/
│   └── app_theme.dart        # colors, gradients, spacing, ThemeData
├── models/                   # Song, NoteEvent, ScoreResult, UserProfile, Achievement
├── config/
│   └── app_config.dart             # build-time config (text2midi endpoint URL)
├── data/
│   ├── game_repository.dart        # storage interface (Firebase-ready)
│   ├── sqlite_game_repository.dart # SQLite (sqflite) implementation
│   ├── db_init.dart                # per-platform database factory
│   └── seed_songs.dart             # demo songs + procedural beat-map generator
├── services/
│   ├── audio_service.dart          # polyphonic piano-tone playback
│   ├── text_to_midi_client.dart    # calls text2midi endpoint, MIDI → Song
│   └── midi_parser.dart            # dependency-free Standard MIDI File parser
├── state/
│   ├── settings_provider.dart
│   ├── profile_provider.dart
│   └── game_controller.dart  # timing, scoring, combo, modes (the engine)
├── widgets/                  # SongCard, PianoTile, ScoreDisplay, Fireworks,
│                             # PianoMuse, GlowButton, GlassCard, GradientText, ...
└── screens/                  # Splash, MainShell, Home, SongSelection, CreateSong,
                              # Game, Result, Profile, Settings, Ranking
assets/
├── fonts/                    # Rubik
├── images/                   # splash artwork
└── sounds/                   # piano tones (note_c4.wav … note_c5.wav)
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.44+ (Dart 3.12+)
- Chrome (for web) or an Android/iOS device or emulator

### Install & run

```bash
flutter pub get

# Web (fastest to preview)
flutter run -d chrome

# Android
flutter run -d <android-device-id>
```

> **Behind a proxy?** If `flutter pub get` fails fetching Git dependencies, clear the proxy for the command (e.g. `HTTP_PROXY= HTTPS_PROXY= flutter pub get`).

---

## 🎧 Audio & Songs

There are no licensed tracks bundled. Instead, piano tones are **synthesized WAVs** and each song ships an original, **procedurally generated beat map** (`lib/data/seed_songs.dart`). When you hit notes accurately, the melody plays back through your taps — Piano-Tiles style.

To add a real track: drop the audio into `assets/`, set `Song.audioFile`, and provide a hand-authored `beat_map` (list of `NoteEvent{time, lane}`). The model already supports it.

**Create from text.** The **＋ Create** button on Song Selection sends your prompt to a self-hosted [text2midi](https://github.com/amaai-lab/text2midi) endpoint; the returned MIDI is parsed on-device into a 4-lane beat map and saved to your library. The endpoint URL comes from build config (never the UI):

```bash
flutter run --dart-define=MIDI_API_URL=https://your-host/generate
# or: --dart-define-from-file=config/app_config.json
```

---

## 📷 Capturing screenshots

The images above were captured from the app running on an Android emulator:

```bash
adb exec-out screencap -p > screenshots/02-home.png
```

On **web**, a deep-link jumps straight to any screen for capture:

```
http://localhost:<port>/?shot=splash | home | library | game | result | profile | settings
```

(Web also needs a one-time `dart run sqflite_common_ffi_web:setup` so the SQLite WASM backend is present.) Replace the files in `screenshots/` (keep the same names) and the README updates automatically.

---

## 🗺️ Roadmap

- [x] Text-to-song generation (self-hosted text2midi endpoint)
- [x] On-device database (SQLite)
- [ ] Firebase Auth + Firestore (cloud profiles & sync)
- [ ] Online leaderboards & multiplayer battles
- [ ] User-uploaded songs & automatic difficulty generation
- [ ] In-app purchases & cosmetics
- [ ] Real backing-track audio

---

## 📄 License

MIT — free to use, learn from, and build upon.

<div align="center">

**Built with Flutter** · Tap. Time. Triumph. 🎹

</div>
