# Parakeet - Audiophile Music Player: Comprehensive Project Roadmap & Implementation Tasks

> **Priority Ordering Rationale**: This roadmap is strictly sorted in descending order of **architectural ripple effect** (i.e. how much painful refactoring would be required across the codebase if deferred to later). 
> Foundational theming tokens, desktop settings infrastructure, universal context menus, core queue data structures, repeat/shuffle engines, directory boundaries, and capability-scoped plugin ports are prioritized first so that all subsequent features, panels, DSP pipelines, and decoders are born themeable, testable, manageable, and modular by default.

---

## Architecture & Target Repository Structure

```text
Parakeet/
├── core/                                # Pure domain — zero Qt, zero SQLite, zero platform headers
│   ├── include/core/{entities,ports,services}
│   └── src/{services,dsp}
├── adapters/                            # Hexagonal ports implementations
│   ├── audio/                           # Platform-specific bit-perfect audio outputs
│   │   ├── alsa/                        # Linux ALSA direct hw / PipeWire lock-free backend
│   │   ├── wasapi/                      # Windows WASAPI Exclusive backend
│   │   └── coreaudio/                   # macOS CoreAudio integer backend
│   ├── metadata/                        # TagLib 2.x audio metadata & cover extractor
│   ├── storage/                         # SQLite3 database with FTS5 search
│   └── ui_qt/                           # Qt 6 Quick / QML MusicBee studio UI & theming
│       ├── models/                      # QAbstractListModel implementations
│       ├── providers/                   # QQuickImageProvider for cached art
│       ├── theming/                     # ThemeLoader, JSON schema validator, hot-reloader
│       └── qml/                         # QML desktop interface, menus & vector canvas icons
│           ├── components/              # Universal ContextMenu, VectorIcon, JumpBar, StarRating
│           ├── dialogs/                 # PreferencesDialog, TagEditorDialog, SmartPlaylistDialog
│           └── views/                   # TrackTable, AlbumGrid, AlbumExpanded, QueueView, HistoryView
├── sdk/                                 # Public plugin API — versioned, documented, stable C ABI
│   └── include/parakeet/plugin/         # Plugin manifests, lifecycle, and capability ports
├── plugins/                             # First-party reference plugins dogfooding the SDK
│   ├── spectrum_visualizer/             # Real-time FFT visualizer plugin
│   └── lyrics_scrobbler/                # Synchronized lyrics & Last.fm/ListenBrainz scrobbler
├── app/                                 # Composition root: wires adapters, theme engine & plugin manager
├── tests/                               # Mirrors core/ and adapters/ — unit tests against fake ports
├── docs/                                # Developer, architectural, plugin, and theme documentation
│   ├── ARCHITECTURE.md                  # Explicit hexagonal boundary & port contracts
│   ├── THEMING.md                       # Third-party theme guide, schema docs & worked examples
│   ├── theme-schema.json                # JSON Schema for theme validation
│   └── PLUGIN_API.md                    # Plugin SDK specifications & lifecycle documentation
├── .github/workflows/                   # Cross-platform build matrix, linting & CI/CD
├── CONTRIBUTING.md                      # Open source contributor guidelines
├── CODEOWNERS                           # Repository ownership
├── LICENSE                              # Project license
└── .gitignore
```

---

## Phase 0: Completed Foundations

- [x] **0.1 Core Domain Entities & Port Interfaces**
  - [x] `Track.hpp`, `Album.hpp`, `Artist.hpp`, `Playlist.hpp` domain entities.
  - [x] `IMusicDatabasePort.hpp`, `IMetadataExtractor.hpp`, `IAudioEnginePort.hpp`.
  - [x] `LibraryService.hpp` / `.cpp`: Directory scanning, deduplication, incremental sync.
  - [x] `purgeNonExistentTracks()` & `clearLibrary()`: Database cleanup of deleted/mock files.
  - [x] `PlayerService.hpp` / `.cpp`: Playback queue orchestration.
- [x] **0.2 Metadata & Storage Adapters**
  - [x] `TagLibMetadataAdapter`: Stream property extraction (FLAC, WAV, ALAC, MP3, M4A, OGG), embedded cover art extraction, SHA256 image deduplication.
  - [x] `SqliteDatabaseAdapter`: SQLite3 schema (`tracks`, `albums`, `artists`, `playlists`), indexed search, FTS5 full-text search, cascade deletion.
- [x] **0.3 UI Architecture & MusicBee Studio Layout**
  - [x] Deslopped UI: Zero gradients, zero emojis, 100% custom vector canvas iconography (`VectorIcon.qml`).
  - [x] Multi-Panel Studio Layout: Top Desktop Menu Strip, Command Toolbar, Left Library Explorer, 3-Column Filter Browser (Genre/Artist/Album), Central Multi-View Workspace (Table, Grid, Expanded, A-Z Jump Bar), Right Inspector Panel (Technical audiophile specs), Bottom Transport Deck, and Status Bar.
  - [x] View Models: `TrackListModel`, `AlbumListModel`, `AlbumArtImageProvider` with disk cache.
- [x] **0.4 Playback Engine & Real Library Scanning**
  - [x] `BitPerfectAudioAdapter` backed by `Qt6::Multimedia` (`QMediaPlayer` + `QAudioOutput`) with system PipeWire/ALSA routing.
  - [x] Automatic queue progression on `EndOfMedia`.
  - [x] Real recursive directory scanning with background thread execution and UI progress bar.

---

## Phase 1: Foundational Architecture, Theming, Queue & Power-User Controls (IMMEDIATE PRIORITY — HIGHEST RIPPLE EFFECT)

> **Why do this first?** 
> If deferred, every new panel, dialog, settings screen, playlist manager, and plugin UI will be authored with hardcoded hex colors, fonts, and spacings. Furthermore, building dialogs, right-click menus, and queue data structures early establishes the core interaction model so power-user workflows (Play Next, Show in Folder, Repeat Modes, Album Shuffle, Theme Switch) are baked in from day one.

- [x] **1.1 JSON Design-Token Theming System for Third-Party Themes (`adapters/ui_qt/theming`)**
  - [x] **Theme JSON Schema**: Define comprehensive schema covering:
    - `meta`: `name`, `author`, `version`, `apiVersion` (pre-1.0/unstable), `description`.
    - `colors`: `background`, `surface`, `surfaceElevated`, `panelBorder`, `accent`, `accentHover`, `textPrimary`, `textSecondary`, `textMuted`, `selection`, `error`, `warning`, `success`.
    - `typography`: `fontFamily`, `fontSizeSmall`, `fontSizeBase`, `fontSizeLarge`, `fontSizeTitle`, `fontWeightScale`, `lineHeightScale`.
    - `metrics`: `spacingSmall`, `spacingMedium`, `spacingLarge`, `cornerRadiusSmall`, `cornerRadiusMedium`, `panelPadding`.
    - `icons`: Optional icon set overrides directory.
  - [x] **ThemeLoader Implementation (`adapters/ui_qt/theming/ThemeLoader.{hpp,cpp}`)**:
    - Locate user theme files in `QStandardPaths::AppDataLocation/themes` (`~/.local/share/ParakeetAudio/Parakeet/themes/`).
    - Parse with `QJsonDocument` and validate required fields against the schema.
    - **Robust Error Fallback**: Fall back to built-in default dark studio theme on any parsing/validation error (never crash or render broken UI on a malformed third-party file).
  - [x] **QML Theme Singleton**: Expose the active theme to QML as a typed singleton (`Theme.qml` or C++ `QML_SINGLETON` / context property) providing reactive access to colors, fonts, spacings, and radii.
  - [x] **Hot-Reloading Engine**: Attach `QFileSystemWatcher` to the active theme JSON; instantly re-apply tokens across QML without application restart.
  - [x] **QML Hardcoded Value Refactor**: Audit and refactor `adapters/ui_qt/qml/Main.qml`, `VectorIcon.qml`, and delegates to consume `Theme.*` properties instead of hardcoded hex codes (`#0e0e11`, `#141418`, etc.).
  - [x] **Theme Documentation & Validation Tools**:
    - Write `docs/theme-schema.json` formal JSON Schema.
    - Write `docs/THEMING.md` with a complete worked example theme, token explanations, and a "Why your theme didn't load" troubleshooting guide.
  - [x] **ThemeLoader Unit Tests**: Unit tests under `tests/` covering: valid theme, malformed JSON syntax, missing required fields, non-existent file path, and partial theme with fallback-to-default values.

- [x] **1.2 Comprehensive Queue Engine & Advanced Playback Modes (`QueueService` in `core/`)**
  - [x] **Dynamic Queue Management (`QueueService.hpp` / `.cpp`)**:
    - **Dual-Tier Queue**: "Up Next" (manual user priority queue) + "Main Stream" (album/playlist background sequence).
    - **Queue Actions**:
      - *Play Now*: Clears current queue, sets selected track as active, and queues remaining album/context tracks.
      - *Play Next*: Inserts track/album directly after currently playing song in priority slot.
      - *Queue Last*: Appends track/album to the end of the Up Next queue.
      - *Remove From Queue*: Deletes individual track from queue.
      - *Clear Queue*: Purges all upcoming tracks.
      - *Shuffle Remaining*: Re-randomizes only upcoming unplayed tracks in queue without interrupting current track.
      - *Save Queue as Playlist*: Converts current queue into a permanent static playlist.
    - **Reversible History Stack**: Maintains historical stack of played tracks for accurate "Previous Track" navigation even when playback is randomized.
  - [x] **Right Inspector "Play Queue" Panel (`QueueView.qml`)**:
    - Full list of tracks in current queue with index number, title, artist, duration, and codec badge.
    - Drag-and-drop / up-down track reordering.
    - Header showing total remaining tracks count and cumulative remaining playback duration.
  - [x] **Tri-State Repeat Engine**:
    - `Repeat Off`: Stop playback when queue/album ends.
    - `Repeat All`: Seamlessly loop the entire queue/album indefinitely.
    - `Repeat One`: Indefinitely repeat current track.
    - Transport deck vector icons for all three states (`repeat` off, `repeat` all active, `repeat_one` active with numeric "1" glyph).
  - [x] **Audiophile Shuffle Modes**:
    - **Track Shuffle**: Pure Fisher-Yates randomization with history memory to prevent repeated songs until full library/queue is exhausted.
    - **Album Shuffle**: Shuffles the order of albums, but plays all tracks *within* each album strictly in track-number order (essential for concept albums, classical symphonies, and live sets).
    - Non-destructive toggle: turning shuffle off restores original track/album ordering without losing current playback position.

- [x] **1.3 Comprehensive Preferences & Settings Dialog (`PreferencesDialog.qml`)**
  - [x] **Multi-Category Left Navigation**:
    - Categories: *General*, *Themes & Appearance*, *Audio Output*, *Playback & Queue*, *Library & Monitored Folders*, *Plugins & Extensions*, *Hotkeys & Keyboard Shortcuts*.
  - [x] **Themes & Appearance Tab**:
    - Visual theme card grid showing installed theme name, author, version, and color palette swatches.
    - Active theme selector with 1-click activation (utilizing runtime hot-reload).
    - "Install Theme from File..." file picker dialog (`.json` or theme package).
    - "Open Themes Folder" button using `QDesktopServices::openUrl` to open user file manager.
    - Global UI font scale and density slider (Compact, Standard, Comfortable).
  - [x] **Playback & Queue Tab**:
    - Default action on double-click (Play Now, Play Next, Queue Last).
    - Auto-fill queue mode when queue is empty (Stop, Loop Album, Continue Library).
    - Shuffle mode preference (Track Shuffle vs. Album Shuffle).
  - [x] **Library & Monitored Folders Tab**:
    - List of monitored directory paths with "Add Folder..." and "Remove Folder" buttons.
    - Library maintenance actions: "Rescan All Folders", "Purge Missing Tracks", "Export Database Backup", "Clear Library Database".
    - Auto-scan library on startup toggle.

- [x] **1.4 Desktop Menu Strip Routing & Power-User Navigation**
  - [x] **Top Menu Strip Routing**:
    - **File**: *Add Folder to Library...*, *Open Audio File...*, *Preferences / Settings (Ctrl+,)*, *Separator*, *Exit (Ctrl+Q)*.
    - **View**: *Toggle Left Explorer (Ctrl+1)*, *Toggle 3-Column Browser (Ctrl+2)*, *Toggle Right Inspector (Ctrl+3)*, *Toggle Status Bar*, *Zoom / Scaling*, *Themes Quick Submenu*.
    - **Controls**: *Play/Pause (Space)*, *Stop (Ctrl+.)*, *Next Track (Ctrl+Right)*, *Previous Track (Ctrl+Left)*, *Volume Up/Down (Ctrl+Up/Down)*, *Mute Toggle (Ctrl+M)*, *Shuffle Toggle (Ctrl+S)*, *Repeat Mode (Ctrl+R)*.
    - **Tools**: *Manage Plugins...*, *Tag Editor...*, *Rescan Library*, *Purge Missing Tracks*.
  - [x] **Keyboard Shortcuts & Accelerators**:
    - Space: Play/Pause.
    - Enter: Play selected track.
    - Arrow Up/Down: Navigate track list / table rows.
    - Ctrl+F: Focus instant search bar.
    - Esc: Clear search filter / dismiss modal dialogs.
    - Alt+Left / Alt+Right: Navigation history (Back / Forward across viewed albums and lists).
    - Left / Right Arrow: Seek 5 seconds backward / forward.
    - Shift + Left / Right: Seek 30 seconds backward / forward.

- [x] **1.5 Universal Right-Mouse-Button (RMB) Context Menus (`ContextMenu.qml`)**
  - [x] **Track Table & Album Card Context Menu**:
    - *Play Now* (clears queue and starts playback immediately).
    - *Play Next* (inserts track/album directly after currently playing song).
    - *Add to Queue* (appends to end of now-playing queue).
    - *Add to Playlist >* (cascading submenu listing user playlists + "New Playlist...").
    - *Separator*.
    - *Show in File Manager / Open Containing Folder* (`QDesktopServices::openUrl` selecting file on disk).
    - *View Technical Audiophile Specs* (activates Right Inspector with full audio stream properties).
    - *Copy Audio File Path / Copy Track Information*.
    - *Separator*.
    - *Edit Track Tags & Properties...* (triggers TagEditorDialog).
    - *Remove from Library / Prune Entry*.
  - [x] **Table Column Header Context Menu**:
    - Column visibility toggles (Show/Hide `#`, `Title`, `Artist`, `Album`, `Genre`, `Year`, `Format`, `Bitrate`, `Time`, `Rating`, `Play Count`).
    - "Auto-Size All Columns" to fit content.
    - Sort ascending / descending shortcuts.
  - [x] **Left Explorer Tree Context Menu**:
    - *Rescan This Folder*.
    - *New Playlist*.
    - *New Smart Playlist...*.
    - *Export Playlist (M3U/M3U8)*.
    - *Rename / Delete Playlist*.

- [x] **1.6 Hexagonal Directory Restructuring & Architectural Boundary Cleanup**
  - [x] Restructure directory layout to strictly match the canonical architecture:
    - Split audio backends into `adapters/audio/{alsa,wasapi,coreaudio}/`.
    - Group Qt UI adapter cleanly into `adapters/ui_qt/{models,providers,theming,qml}/`.
    - Create `sdk/` and `plugins/` top-level roots in CMake.
  - [x] Write `docs/ARCHITECTURE.md`: Explicitly document hexagonal boundaries, thread models, port contracts, and data-flow rules.
  - [x] Set up `tests/` CMake target with mock/fake ports for unit testing core domain services without database or audio hardware dependencies.

- [x] **1.7 Core Plugin Extension Ports in `core/` (Capability-Scoped Interfaces)**
  - [x] *Rationale*: Defining plugin extension points as ports in `core/` ensures future DSP filters, scrapers, and visualizers attach to ports rather than becoming hardwired monoliths.
  - [x] Add `core/include/core/ports/IPlayerPlugin.hpp`: Real-time audio buffer hooks (pre/post-DSP processing, stream metadata).
  - [x] Add `core/include/core/ports/ILibraryPlugin.hpp`: Alternate metadata providers, lyrics scrapers, scrobbler hooks.
  - [x] Add `core/include/core/ports/IVisualizerPlugin.hpp`: Real-time PCM visualizer buffer consumer and rendering surface provider.
  - [x] Capability scoping: Ensure each plugin port is strictly isolated with independent lifecycle methods.

---

## Phase 2: Dogfood Reference Plugins & Public SDK Extraction (HIGH RIPPLE EFFECT)

> **Why do this second?** 
> Publishing an SDK before dogfooding it guarantees breaking changes and developer friction. Writing two internal reference plugins against the core ports first uncovers all interface flaws before the public ABI is stabilized.

- [ ] **2.1 First-Party Reference Dogfood Plugins (`plugins/`)**
  - [ ] Build reference plugins as standalone CMake targets touching *only* the port headers:
    - **Plugin 1 (`spectrum_visualizer`)**: Real-time FFT audio spectrum analyzer consuming `IVisualizerPlugin`.
    - **Plugin 2 (`lyrics_scrobbler`)**: Synchronized lyrics provider and scrobbler consuming `ILibraryPlugin` and `IPlayerPlugin`.
  - [ ] Validate runtime loading without linking to `core` or `adapters` internals.
- [ ] **2.2 Public SDK Extraction (`sdk/include/parakeet/plugin/`)**
  - [ ] Pull verified headers into `sdk/include/parakeet/plugin/`.
  - [ ] **Stable C-Style ABI Boundary**: Implement `extern "C"` plugin factory (`extern "C" PARAKEET_PLUGIN_EXPORT IParakeetPlugin* create_plugin()`) to eliminate cross-compiler STL ABI incompatibilities.
  - [ ] **Plugin Manifest Specification**: Define JSON manifest (`plugin.json`) with plugin name, author, declared capabilities, target API version, and dependencies.
  - [ ] **Independent Plugin API Versioning**: Define `PARAKEET_PLUGIN_API_VERSION` independently of the application release version.
  - [ ] **PluginManager Adapter in `app/`**: Dynamic loading (`dlopen` / `LoadLibrary`), checksum verification, version validation, and capability routing.
  - [ ] **Plugin Management Tab in Preferences**:
    - Display discovered plugins with manifest information (name, author, version, target API compatibility status).
    - Enable / Disable toggle per plugin.
    - "Configure Plugin..." button opening plugin-specific settings dialog.
    - "Open Plugins Directory" button.
  - [ ] Write `docs/PLUGIN_API.md`: Developer guide for authoring, building, and packaging C++ and QML plugins.

---

## Phase 3: Bit-Perfect Hardware Audio Pipeline, DSP & Audiophile Playback (MEDIUM-HIGH RIPPLE EFFECT)

> **Why do this third?** 
> With the core plugin ports in place, the audio processing pipeline can cleanly expose the `IPlayerPlugin` DSP hooks (EQ, volume dithering, ReplayGain, crossfade) directly in the audio rendering loop.

- [ ] **3.1 Dedicated Low-Latency / Bit-Perfect Hardware Adapters (`adapters/audio/`)**
  - [ ] Linux ALSA direct `hw:` mode and PipeWire lock-free backend (`adapters/audio/alsa/`).
  - [ ] Windows WASAPI Exclusive Mode backend (`adapters/audio/wasapi/`).
  - [ ] macOS CoreAudio integer/exclusive mode (`adapters/audio/coreaudio/`).
  - [ ] Lock-free Single-Producer Single-Consumer (SPSC) ring buffer bridging decoder threads to the high-priority audio callback.
  - [ ] **Audio Output Tab in Preferences Dialog**:
    - Device output selector (ALSA hardware devices, PipeWire streams, WASAPI Exclusive endpoints).
    - Bit-perfect exclusive mode toggle.
    - Buffer latency slider (10ms - 250ms).
    - Sample rate conversion mode (Direct bit-perfect / High-quality SoX resampler fallback).
- [ ] **3.2 Sample-Accurate Gapless Playback & Crossfade Engine**
  - [ ] **Sample-Accurate Gapless Playback**: Pre-decode upcoming track into a secondary ring buffer, seamlessly splicing PCM streams with zero silence, pops, or clicks between tracks (vital for live albums, opera, and concept albums).
  - [ ] **Customizable Crossfade Engine**: Configurable crossfade duration (0s - 10s) with equal-power logarithmic curves for non-gapless playback.
- [ ] **3.3 ReplayGain 2.0 & Loudness Normalization**
  - [ ] Read ReplayGain tags (`REPLAYGAIN_TRACK_GAIN`, `REPLAYGAIN_TRACK_PEAK`, `REPLAYGAIN_ALBUM_GAIN`, `REPLAYGAIN_ALBUM_PEAK`) and EBU R128 loudness tags.
  - [ ] Mode switch: *Track Gain* (equal loudness across mixed playlists) vs. *Album Gain* (preserves dynamic relationships across songs on an album).
  - [ ] Pre-amplification gain slider (-12 dB to +12 dB) with true-peak anti-clipping limiter.
- [ ] **3.4 Dedicated In-Process Decoders**
  - [ ] Direct `libFLAC` / `dr_flac` integration for bit-perfect PCM streaming.
  - [ ] Direct `dr_wav` / `libsndfile` for WAV and AIFF uncompressed audio.
  - [ ] Native DSD / DoP (DSD over PCM) decoding pipeline for DSF/DFF formats.
  - [ ] FFmpeg / Symphonia fallback pipeline for ALAC, AAC, Opus, Vorbis, and MP3.
- [ ] **3.5 Audiophile DSP Pipeline (Implemented via `IPlayerPlugin`)**
  - [ ] 10-band / 31-band Parametric Equalizer using high-precision biquad IIR filters with graphical EQ curve editor.
  - [ ] 64-bit float dithering (TPDF) and bit-perfect digital volume attenuation.
- [ ] **3.6 Audiophile Utilities: Sleep Timer, A-B Looping & Pitch Control**
  - [ ] **Sleep Timer**: Stop playback after X minutes (15m, 30m, 45m, 60m, custom), or after current track / album ends, with optional 30-second smooth fade-out.
  - [ ] **A-B Looping**: Set point A and point B on timeline to loop a specific passage indefinitely.
  - [ ] **Variable Speed & Pitch Control**: 0.5x to 2.0x playback rate with pitch preservation.

---

## Phase 4: Advanced Playlists, Library Management, Ratings & Tagging (MEDIUM RIPPLE EFFECT)

> **Why do this fourth?** 
> These features expand library capability and ergonomics without modifying core contracts or invalidating UI design tokens.

- [ ] **4.1 Comprehensive Playlist System (Static & Smart Playlists)**
  - [ ] **Static Playlists (`PlaylistService.hpp` / SQLite `playlists` & `playlist_tracks`)**:
    - Create, rename, duplicate, and delete playlists.
    - Drag-and-drop manual reordering of tracks within playlists.
    - Full import and export: M3U, M3U8 (UTF-8 with extended `#EXTINF` metadata), PLS, and XSPF formats.
    - Relative file path resolution for portable USB drives and music libraries.
  - [ ] **Smart Auto-Playlists (Dynamic Rule Engine)**:
    - Filter rules engine with Match ALL / Match ANY conditions:
      - Genre, Artist, Album, Year range.
      - Audio quality: Bit Depth (e.g. `>= 24`), Sample Rate (e.g. `>= 96000`), Codec (e.g. `FLAC`).
      - Play statistics: Play count (e.g. `>= 10`), Date added (e.g. `within last 30 days`), Last played, Rating (e.g. `>= 4 stars`).
    - Built-in default smart playlists in Left Explorer:
      - *Recently Added* (tracks added in the last 30 days).
      - *Most Played* (top 100 tracks by play count).
      - *Hi-Res Audio* (24-bit / 96k+ tracks).
      - *Top Rated* (4 and 5-star rated tracks).
      - *Forgotten Gems* (tracks in library with play count < 2).
      - *Decades* (70s, 80s, 90s, 2000s, 2010s, 2020s).
  - [ ] **Drag & Drop Workflow**: Drag tracks or album cards from main view directly onto playlist nodes in the Left Library Explorer.
- [ ] **4.2 Track Ratings, Favorites & Listening Statistics**
  - [ ] **5-Star Rating System & Favorites Heart**:
    - Interactive 0–5 star rating widget in Track Table, Right Inspector, and Bottom Transport Deck.
    - Quick "Favorite / Love" toggle.
    - Stored in SQLite and optionally written back to audio file ID3v2 (`POPM` frame) / Vorbis tags (`RATING`).
  - [ ] **Listening Statistics Tracking**:
    - `PlayCount`, `SkipCount`, and `LastPlayedTimestamp` updated in SQLite.
    - Standard scrobbling threshold: track counts as played after 50% or 4 minutes of playback.
  - [ ] **Listening History Timeline View**:
    - Dedicated view accessible from Left Explorer showing chronological playback history grouped by Today, Yesterday, This Week, and Older.
- [ ] **4.3 Real-Time Filesystem Watcher**
  - [ ] Background filesystem watcher (`QFileSystemWatcher` / inotify / ReadDirectoryChangesW).
  - [ ] Incremental synchronization: auto-detect newly added, modified, or deleted tracks with minimal database re-indexing.
- [ ] **4.4 Folder Navigation Tree View**
  - [ ] Physical directory breadcrumb and tree view in the Left Library Explorer.
  - [ ] Direct playback of unindexed folders and external media drives.
- [ ] **4.5 Metadata Tag Editor Dialog (`TagEditorDialog.qml`)**
  - [ ] Multi-track batch tag editor dialog launched from context menu or Tools menu.
  - [ ] Batch editing of Title, Artist, Album, Album Artist, Genre, Year, Track Number, and Disc Number using TagLib.
  - [ ] Embedded cover art injector, extractor, and replacement tool.

---

## Phase 5: Open Source Governance, CI/CD & Cross-Platform Packaging (LOWEST CODE CHURN)

> **Why do this fifth?** 
> Repository governance, CI/CD matrices, and packaging scripts should lock down and distribute a stable, tested architecture rather than churning with early refactoring.

- [ ] **5.1 Community Governance & Repository Polish**
  - [ ] `CONTRIBUTING.md`: Coding standards, PR guidelines, build instructions, and issue templates.
  - [ ] `CODEOWNERS` and `LICENSE` (GPLv3 or MIT).
  - [ ] Modern, informative `README.md` with architecture badges, visual screenshots, and quick-start instructions.
- [ ] **5.2 CI/CD Automation (`.github/workflows/`)**
  - [ ] Cross-platform GitHub Actions matrix builds (Ubuntu, Windows Server, macOS).
  - [ ] Automated unit test runner (`ctest --output-on-failure`).
  - [ ] Static analysis and formatting enforcement (`clang-tidy`, `clang-format`).
- [ ] **5.3 Cross-Platform Packaging Targets**
  - [ ] Linux: AppImage, Flatpak, and native `.deb` / `.rpm` packages.
  - [ ] Windows: Standalone portable zip and MSIX / InnoSetup installer.
  - [ ] macOS: Notarized `.dmg` / `.app` bundle with Universal 2 binaries (Apple Silicon & Intel).
