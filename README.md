# Parakeet

Parakeet is a modern, high-performance, bit-perfect desktop audio player and music library manager designed for audiophiles and power users. Built on a clean architecture foundation using modern **C++20** and **Qt 6 / QML**.

---

## Features

- **Bit-Perfect Audio Pipeline**: Powered by Qt 6 Multimedia and FFmpeg backends supporting FLAC, ALAC, WAV, AIFF, DSD, MP3, and AAC.
- **DSP & Dynamics Control**: Gapless playback, customizable crossfade curves, ReplayGain 2.0 loudness normalization, and True-Peak limiting.
- **Fast Local Library**: SQLite3-powered metadata store with incremental quick scanning and real-time filesystem watching.
- **Robust Metadata Tagging**: Deep TagLib integration for multi-track batch tag editing, embedded artwork caching, and file renaming.
- **Ergonomic Desktop Interface**:
  - Multi-column Track Table with 17 customizable metadata columns, column auto-sizing, and persistent widths.
  - Universal right-click context menus with multi-selection support, ratings, and playlist management.
  - 3-column Column Browser (Genres, Artists, Albums) and responsive Album Grid views.
  - Detachable compact Mini-Player and dedicated Right Inspector panel.
- **Listening Sync**: Scrobbling support for Last.fm and ListenBrainz protocols with offline caching.
- **Dynamic Theming**: Real-time hot-reloading JSON design tokens and theme engine.

---

## Architecture Overview

Parakeet adheres to Clean Architecture principles to separate core domain logic from framework dependencies:

```
Parakeet/
├── core/            # Domain logic, entities, ports, and services (pure C++20, no Qt)
├── adapters/        # Infrastructure adapters:
│   ├── audio/       # Bit-perfect audio playback backend
│   ├── metadata/    # TagLib metadata extraction & artwork parsing
│   ├── storage/     # SQLite database repository
│   └── ui_qt/       # Qt/QML bridge, view models, and UI components
├── app/             # Application composition root wiring adapters to services
├── sdk/             # Public C-ABI plugin interfaces
├── plugins/         # First-party reference plugins
├── tests/           # Unit test suite and mocks
└── docs/            # Architecture decision records and theme schema
```

---

## Building from Source

For comprehensive build prerequisites, toolchain setups, and platform-specific commands, see [CONTRIBUTING.md](CONTRIBUTING.md).

```bash
# Clone the repository
git clone https://github.com/ShamalLakshan/Parakeet.git
cd Parakeet

# Configure and compile
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)

# Run test suite
ctest --test-dir build --output-on-failure

# Launch Parakeet
./build/app/Parakeet
```

---

## Acknowledgements & Attributions

Parakeet stands on the shoulders of outstanding open-source libraries, audio standards, and pioneer desktop audio players:

### Core Libraries & Toolkits
- [Qt 6](https://www.qt.io/)
- [TagLib](https://taglib.org/)
- [SQLite](https://www.sqlite.org/)
- [FFmpeg](https://ffmpeg.org/)
- [GoogleTest](https://github.com/google/googletest)

### Audio Standards & Protocols
- [ReplayGain 2.0 Specification](https://wiki.hydrogenaud.io/index.php?title=ReplayGain_2.0_specification)
- [ITU-R BS.1770-4](https://www.itu.int/rec/R-REC-BS.1770/en)
- [M3U / Extended M3U8 Playlist Format](https://en.wikipedia.org/wiki/M3U)
- [Audioscrobbler Protocol](https://www.last.fm/api/scrobbling)
- [ListenBrainz API](https://listenbrainz.readthedocs.io/en/latest/users/api/)

### Desktop Player Ergonomics & Design References
- [foobar2000](https://www.foobar2000.org/)
- [MusicBee](https://getmusicbee.com/)
- [Strawberry Music Player](https://www.strawberrymusicplayer.org/)
- [Clementine](https://www.clementine-player.org/)

### Typography & Visual Design
- [Inter Typeface](https://rsms.me/inter/)
- [Tabler Icons](https://tabler-icons.io/)
- [Feather Icons](https://feathericons.com/)

---

## License

Parakeet is licensed under the [GNU Affero General Public License v3.0 (AGPL-3.0)](LICENSE).
