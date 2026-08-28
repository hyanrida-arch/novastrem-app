# NovaStream

A full-featured IPTV client (Xtream Codes + M3U) built with Flutter, in the
style of IPTV Smarters Pro.

## Stack

- **State management:** Riverpod (plain providers/`StateNotifier`, no code
  generation required — the project builds with zero `build_runner` steps).
- **Video playback:** `flutter_vlc_player` (libVLC), for robust `m3u8` /
  `mp4` / `mkv` / `ts` support across live and VOD streams.
- **Local storage:** Hive (session/auth) — `favoritesBox` is wired up and
  ready for a Favorites feature.
- **Architecture:** Clean Architecture per feature — `domain` (entities,
  repository contracts, usecases) → `data` (models, datasources, repository
  impls) → `presentation` (Riverpod providers, screens, widgets).

## Getting started

```bash
flutter pub get
flutter run
```

## Project layout

```
lib/
├── main.dart                     # Hive bootstrap, runApp
├── app.dart                      # MaterialApp, theme, routes, session-based start screen
├── core/                         # Cross-cutting: theme, network, storage, shared models
│   ├── constants/                # Colors, strings, Xtream action names
│   ├── error/                    # Failure types
│   ├── models/                   # XtreamCredentials (shared across features)
│   ├── network/                  # ApiClient (Dio), Dio error mapper
│   ├── providers/                # xtreamCredentialsProvider (derives creds from session)
│   ├── routes/                   # Named route constants
│   ├── storage/                  # HiveService bootstrap
│   ├── theme/                    # AppTheme
│   ├── utils/                    # Result<T>, XtreamUrlBuilder
│   └── widgets/                  # Loading/Error/Empty state views
└── features/
    ├── auth/                     # Xtream + M3U login, session persistence
    ├── live_tv/                  # Categories → Channels → Player
    ├── vod/                      # Categories → Movie grid → Details → Player
    ├── series/                   # Categories → Series grid → Seasons/Episodes → Player
    ├── player/                   # Shared PlayerScreen (flutter_vlc_player)
    └── dashboard/                # App shell: brand app bar + bottom nav
```

Each feature under `features/` follows the same three-layer split:

```
feature/
├── data/
│   ├── datasources/   # Dio calls against player_api.php, JSON parsing
│   ├── models/        # *Model.fromJson(...) + toEntity()
│   └── repositories/  # Catches Dio/parse errors → Result<Failure|T>
├── domain/
│   ├── entities/       # Plain Dart, no JSON/Dio/Hive knowledge
│   ├── repositories/    # Abstract contracts
│   └── usecases/        # One class per action, called from providers
└── presentation/
    ├── providers/    # Riverpod wiring + FutureProviders
    ├── screens/
    └── widgets/
```

## Verified in this environment

- `flutter pub get` — resolves cleanly.
- `flutter analyze` — **no issues found**.
- `flutter test` — smoke test passes (boots to the login screen, brand + login button render).

Running on a simulator/device was **not** verified here: this machine has
Xcode command-line tools only (no full Xcode) and no Android `cmdline-tools`
installed, so neither `flutter run` target is available in this sandbox. See
below to run it yourself.

## Running for real

**iOS:** install Xcode from the App Store, then:
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
flutter run -d ios
```

**Android:** install Android Studio (or standalone `cmdline-tools`), accept
licenses, then:
```bash
flutter doctor --android-licenses
flutter run -d android
```

## Known follow-ups (intentionally left as-is for a starter template)

- **Logo:** [`NovaStreamLogo`](lib/features/auth/presentation/widgets/novastream_logo.dart)
  is a gradient placeholder badge + wordmark. Drop real artwork into
  `assets/images/` and swap the `Icon` for `Image.asset(...)`.
- **M3U parsing:** login validates the URL returns a real `#EXTM3U`
  playlist and persists the session, but Live TV/VOD/Series screens
  currently only render for Xtream Codes sessions
  (`xtreamCredentialsProvider` returns `null` for M3U). Add an M3U parser
  data source (e.g. via the `m3u` package) and a parallel provider path to
  light up those screens for M3U users too.
- **Favorites:** `HiveService.favoritesBox` is opened at startup and ready
  to use; no UI wired to it yet.
- **EPG:** `ChannelEntity.epgChannelId` is parsed and available for a
  future "now/next" programme-guide feature.
# novastrem-app
