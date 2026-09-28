#include "QtBridge.hpp"
#include "core/ports/IMetadataExtractor.hpp"
#include "core/ports/IMusicDatabasePort.hpp"
#include "core/services/LibraryService.hpp"
#include "core/services/PlayerService.hpp"
#include "mocks/MockAudioEnginePort.hpp"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QSettings>
#include <QStandardPaths>
#include <gtest/gtest.h>

namespace {

class MockDb : public core::IMusicDatabasePort {
public:
  std::vector<core::Track> tracks;
  bool initialize(const std::string &) override { return true; }
  bool saveTrack(const core::Track &t) override {
    tracks.push_back(t);
    return true;
  }
  bool saveTracks(const std::vector<core::Track> &ts) override {
    tracks.insert(tracks.end(), ts.begin(), ts.end());
    return true;
  }
  std::optional<core::Track> getTrackById(const std::string &id) override {
    for (const auto &t : tracks) {
      if (t.id == id)
        return t;
    }
    return std::nullopt;
  }
  std::optional<core::Track> getTrackByPath(const std::string &path) override {
    for (const auto &t : tracks) {
      if (t.filePath == path)
        return t;
    }
    return std::nullopt;
  }
  std::vector<core::Track> getAllTracks() override { return tracks; }
  std::vector<core::Track> getTracksByAlbum(const std::string &,
                                            const std::string &) override {
    return {};
  }
  bool deleteTrack(const std::string &id) override {
    std::erase_if(tracks, [&](const auto &t) { return t.id == id; });
    return true;
  }
  std::vector<core::Album> getAllAlbums() override { return {}; }
  std::optional<core::Album> getAlbumById(const std::string &) override {
    return std::nullopt;
  }
  bool clearLibrary() override {
    tracks.clear();
    return true;
  }
  bool optimizeDatabase() override { return true; }
  size_t getTrackCount() override { return tracks.size(); }
  size_t getAlbumCount() override { return 0; }
};

class MockExtractor : public core::IMetadataExtractor {
public:
  std::optional<core::Track> extract(const std::string &) override {
    return std::nullopt;
  }
  std::optional<core::ExtractedArtwork>
  extractArtwork(const std::string &) override {
    return std::nullopt;
  }
  bool supportsFormat(const std::string &) const override { return true; }
};

} // namespace

class SettingsTest : public ::testing::Test {
protected:
  static void SetUpTestSuite() {
    int argc = 1;
    static char appName[] = "parakeet_tests";
    static char *argv[] = {appName, nullptr};
    if (!QCoreApplication::instance()) {
      new QCoreApplication(argc, argv);
    }
    QCoreApplication::setOrganizationName("ParakeetAudio");
    QCoreApplication::setApplicationName("ParakeetTest");
  }

  void SetUp() override {
    QSettings s("ParakeetAudio", "ParakeetTest");
    s.clear();
  }

  void TearDown() override {
    QSettings s("ParakeetAudio", "ParakeetTest");
    s.clear();
  }
};

TEST_F(SettingsTest, GeneralSettingsGettersAndSetters) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Language
  bridge.setLanguage("Deutsch");
  EXPECT_EQ(bridge.language(), "Deutsch");

  // Startup Action
  bridge.setStartupAction("Play Immediately");
  EXPECT_EQ(bridge.startupAction(), "Play Immediately");

  // Close & Minimize
  bridge.setCloseAction("Minimize to System Tray");
  EXPECT_EQ(bridge.closeAction(), "Minimize to System Tray");
  bridge.setMinimizeAction("Minimize to System Tray");
  EXPECT_EQ(bridge.minimizeAction(), "Minimize to System Tray");

  // Single-instance
  bridge.setSingleInstance(false);
  EXPECT_FALSE(bridge.singleInstance());
  bridge.setSingleInstance(true);
  EXPECT_TRUE(bridge.singleInstance());

  // Software updates
  bridge.setUpdateCheckInterval("Daily");
  EXPECT_EQ(bridge.updateCheckInterval(), "Daily");

  // Notifications
  bridge.setShowNotifications(false);
  EXPECT_FALSE(bridge.showNotifications());
  bridge.setNotificationDurationSec(8);
  EXPECT_EQ(bridge.notificationDurationSec(), 8);
  bridge.setSuppressNotificationsWhenFocused(false);
  EXPECT_FALSE(bridge.suppressNotificationsWhenFocused());
}

TEST_F(SettingsTest, AppearanceSettingsGettersAndSetters) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Typography
  bridge.setFontFamily("Roboto, sans-serif");
  EXPECT_EQ(bridge.fontFamily(), "Roboto, sans-serif");
  bridge.setBaseFontSize(14);
  EXPECT_EQ(bridge.baseFontSize(), 14);

  // Table & Layout
  bridge.setTableRowHeight(40);
  EXPECT_EQ(bridge.tableRowHeight(), 40);
  bridge.setTableAlternatingRows(true);
  EXPECT_TRUE(bridge.tableAlternatingRows());
  bridge.setWaveformSeekbar(false);
  EXPECT_FALSE(bridge.waveformSeekbar());
  bridge.setShowStatusBar(false);
  EXPECT_FALSE(bridge.showStatusBar());

  // Cover art
  bridge.setArtThumbnailQuality("Balanced (Bilinear)");
  EXPECT_EQ(bridge.artThumbnailQuality(), "Balanced (Bilinear)");
  bridge.setArtCacheLimitMb(2048);
  EXPECT_EQ(bridge.artCacheLimitMb(), 2048);
}

TEST_F(SettingsTest, AudioSettingsGettersAndSetters) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Backend
  bridge.setAudioBackend("ALSA Direct Hardware (hw:)");
  EXPECT_EQ(bridge.audioBackend(), "ALSA Direct Hardware (hw:)");

  // Device
  EXPECT_FALSE(bridge.availableAudioDevices().isEmpty());
  bridge.setCurrentAudioDevice("Custom DAC");
  EXPECT_EQ(bridge.currentAudioDevice(), "Custom DAC");

  // Exclusive mode & Latency
  bridge.setBitPerfectExclusive(false);
  EXPECT_FALSE(bridge.bitPerfectExclusive());
  bridge.setBufferLatencyMs(20);
  EXPECT_EQ(bridge.bufferLatencyMs(), 20);

  // DSP
  bridge.setResamplerQuality("Speex Resampler");
  EXPECT_EQ(bridge.resamplerQuality(), "Speex Resampler");
  bridge.setDitherMode("High-Pass TPDF");
  EXPECT_EQ(bridge.ditherMode(), "High-Pass TPDF");
  bridge.setChannelProcessing("Mono Downmix");
  EXPECT_EQ(bridge.channelProcessing(), "Mono Downmix");
}

TEST_F(SettingsTest, PlaybackDSPSettingsGettersAndSetters) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Gapless & Crossfade
  bridge.setGaplessPlayback(false);
  EXPECT_FALSE(bridge.gaplessPlayback());
  bridge.setGaplessPlayback(true);
  EXPECT_TRUE(bridge.gaplessPlayback());

  bridge.setCrossfadeEnabled(true);
  EXPECT_TRUE(bridge.crossfadeEnabled());
  bridge.setCrossfadeDurationSec(3.5);
  EXPECT_DOUBLE_EQ(bridge.crossfadeDurationSec(), 3.5);
  bridge.setCrossfadeCurve("Logarithmic Fade");
  EXPECT_EQ(bridge.crossfadeCurve(), "Logarithmic Fade");

  // ReplayGain
  bridge.setReplayGainMode("Album Gain (Preserves Album Dynamics)");
  EXPECT_EQ(bridge.replayGainMode(), "Album Gain (Preserves Album Dynamics)");
  bridge.setReplayGainPreampDb(3);
  EXPECT_EQ(bridge.replayGainPreampDb(), 3);
  bridge.setReplayGainPreampWithoutGainDb(-3);
  EXPECT_EQ(bridge.replayGainPreampWithoutGainDb(), -3);
  bridge.setTruePeakLimiter(false);
  EXPECT_FALSE(bridge.truePeakLimiter());

  // Seek & Stop
  bridge.setShortSeekStepSec(3);
  EXPECT_EQ(bridge.shortSeekStepSec(), 3);
  bridge.setLongSeekStepSec(45);
  EXPECT_EQ(bridge.longSeekStepSec(), 45);
  bridge.setStopAfterCurrentTrack(true);
  EXPECT_TRUE(bridge.stopAfterCurrentTrack());
}

TEST_F(SettingsTest, QueueSettingsGettersAndSetters) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Click Actions
  bridge.setDoubleClickAction("Play Next");
  EXPECT_EQ(bridge.doubleClickAction(), "Play Next");
  bridge.setMiddleClickAction("Play Now");
  EXPECT_EQ(bridge.middleClickAction(), "Play Now");

  // Queue End Behavior
  bridge.setQueueAutoFillMode("Smart Autoplay (Similar Tracks)");
  EXPECT_EQ(bridge.queueAutoFillMode(), "Smart Autoplay (Similar Tracks)");

  // Shuffle Strategy
  bridge.setShuffleMode(2);
  EXPECT_EQ(bridge.shuffleMode(), 2);

  // History
  bridge.setHistoryRetentionLimit(500);
  EXPECT_EQ(bridge.historyRetentionLimit(), 500);
  EXPECT_EQ(player.getHistoryLimit(), 500);

  bridge.clearPlaybackHistory();
  EXPECT_TRUE(player.getQueueService().getHistory().empty());
}

TEST_F(SettingsTest, LibrarySettingsGettersAndSetters) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Monitored Folders & Watcher
  bridge.setFilesystemWatcher(false);
  EXPECT_FALSE(bridge.filesystemWatcher());
  bridge.setAutoScanOnStartup(true);
  EXPECT_TRUE(bridge.autoScanOnStartup());

  // Format Filters
  QStringList customFormats = {"FLAC", "DSD (DSF/DFF)", "OPUS"};
  bridge.setFormatFilters(customFormats);
  EXPECT_EQ(bridge.formatFilters(), customFormats);
  EXPECT_TRUE(bridge.isFormatFilterEnabled("FLAC"));
  EXPECT_FALSE(bridge.isFormatFilterEnabled("MP3"));

  bridge.setFormatFilterEnabled("MP3", true);
  EXPECT_TRUE(bridge.isFormatFilterEnabled("MP3"));
  bridge.setFormatFilterEnabled("FLAC", false);
  EXPECT_FALSE(bridge.isFormatFilterEnabled("FLAC"));

  // Exclude Folders & Artwork Priority
  bridge.setExcludeFolders(".*, temp, build");
  EXPECT_EQ(bridge.excludeFolders(), ".*, temp, build");
  bridge.setArtworkPriority("External Folder Art First");
  EXPECT_EQ(bridge.artworkPriority(), "External Folder Art First");

  // Database maintenance
  bridge.optimizeDatabase();
}

TEST_F(SettingsTest, HotkeysSettingsAndConflictDetection) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Global media keys
  EXPECT_TRUE(bridge.globalMediaKeysEnabled());
  bridge.setGlobalMediaKeysEnabled(false);
  EXPECT_FALSE(bridge.globalMediaKeysEnabled());

  // Hotkeys model
  auto model = bridge.hotkeysModel();
  EXPECT_FALSE(model.isEmpty());

  // Conflict detection
  EXPECT_EQ(bridge.checkHotkeyConflict("custom_action", "Space"),
            "Play / Pause playback");
  EXPECT_EQ(bridge.checkHotkeyConflict("play_pause", "Space"), "");
  EXPECT_EQ(bridge.checkHotkeyConflict("custom_action", "Ctrl+Shift+Alt+Z"),
            "");

  // Rebind and restore
  bridge.setHotkey("play_pause", "Ctrl+P");
  EXPECT_EQ(bridge.checkHotkeyConflict("custom_action", "Ctrl+P"),
            "Play / Pause playback");

  bridge.restoreDefaultHotkeys();
  EXPECT_EQ(bridge.checkHotkeyConflict("custom_action", "Space"),
            "Play / Pause playback");
}

TEST_F(SettingsTest, MetadataAndScrobblingSettings) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Last.fm
  bridge.setLastfmEnabled(true);
  EXPECT_TRUE(bridge.lastfmEnabled());
  bridge.setLastfmUsername("audiophile_user");
  EXPECT_EQ(bridge.lastfmUsername(), "audiophile_user");
  bridge.setLastfmSessionKey("session_token_12345");
  EXPECT_EQ(bridge.lastfmSessionKey(), "session_token_12345");

  // ListenBrainz
  bridge.setListenbrainzEnabled(true);
  EXPECT_TRUE(bridge.listenbrainzEnabled());
  bridge.setListenbrainzToken("lb_api_key_abc");
  EXPECT_EQ(bridge.listenbrainzToken(), "lb_api_key_abc");
  bridge.setListenbrainzApiUrl("https://custom.listenbrainz.instance/api/");
  EXPECT_EQ(bridge.listenbrainzApiUrl(),
            "https://custom.listenbrainz.instance/api/");

  // Thresholds & Cache
  bridge.setScrobbleThresholdPercent(75);
  EXPECT_EQ(bridge.scrobbleThresholdPercent(), 75);
  bridge.setScrobbleThresholdTimeSec(180);
  EXPECT_EQ(bridge.scrobbleThresholdTimeSec(), 180);
  bridge.setOfflineScrobbleCache(false);
  EXPECT_FALSE(bridge.offlineScrobbleCache());

  // Lyrics
  bridge.setLyricsProviderOrder("Embedded USLT/SYLT tags first");
  EXPECT_EQ(bridge.lyricsProviderOrder(), "Embedded USLT/SYLT tags first");
  bridge.setAutoFetchLyrics(false);
  EXPECT_FALSE(bridge.autoFetchLyrics());
}

TEST_F(SettingsTest, DiagnosticsAndFactoryReset) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Logging verbosity
  bridge.setLoggingVerbosity("Debug");
  EXPECT_EQ(bridge.loggingVerbosity(), "Debug");

  // Integrity check
  QString integrityStatus = bridge.checkDatabaseIntegrity();
  EXPECT_FALSE(integrityStatus.isEmpty());
  EXPECT_TRUE(integrityStatus.contains("Integrity check passed"));

  // Diagnostics report export
  QString reportPath = QDir::tempPath() + "/parakeet_diag_test.txt";
  bridge.exportDiagnosticsReport(reportPath);
  EXPECT_TRUE(QFile::exists(reportPath));
  QFile::remove(reportPath);

  // Reset to defaults
  bridge.setLanguage("Japanese");
  bridge.setBaseFontSize(18);
  bridge.setLastfmEnabled(true);
  bridge.setLoggingVerbosity("Error");

  bridge.resetAllSettingsToDefaults();

  EXPECT_EQ(bridge.language(), "System Default");
  EXPECT_EQ(bridge.baseFontSize(), 11);
  EXPECT_FALSE(bridge.lastfmEnabled());
  EXPECT_EQ(bridge.loggingVerbosity(), "Info");
  EXPECT_TRUE(bridge.globalMediaKeysEnabled());
}

TEST_F(SettingsTest, TrackListModelSelection) {
  MockDb db;
  TrackListModel model(&db);

  core::Track t1;
  t1.id = "t1";
  t1.title = "Song 1";
  t1.artist = "Artist 1";
  t1.durationMs = 180000;

  core::Track t2;
  t2.id = "t2";
  t2.title = "Song 2";
  t2.artist = "Artist 2";
  t2.durationMs = 240000;

  core::Track t3;
  t3.id = "t3";
  t3.title = "Song 3";
  t3.artist = "Artist 3";
  t3.durationMs = 200000;

  model.setTracks({t1, t2, t3});
  EXPECT_EQ(model.rowCount(), 3);
  EXPECT_EQ(model.selectedCount(), 0);

  // Toggle selection
  model.toggleSelection(0);
  EXPECT_TRUE(model.isSelected(0));
  EXPECT_FALSE(model.isSelected(1));
  EXPECT_EQ(model.selectedCount(), 1);

  // Set row selected
  model.setRowSelected(1, true);
  EXPECT_EQ(model.selectedCount(), 2);
  EXPECT_TRUE(model.isSelected(1));

  // Invert selection
  model.invertSelection();
  EXPECT_EQ(model.selectedCount(), 1);
  EXPECT_FALSE(model.isSelected(0));
  EXPECT_FALSE(model.isSelected(1));
  EXPECT_TRUE(model.isSelected(2));

  // Select all
  model.selectAll();
  EXPECT_EQ(model.selectedCount(), 3);
  EXPECT_TRUE(model.isSelected(0));
  EXPECT_TRUE(model.isSelected(1));
  EXPECT_TRUE(model.isSelected(2));

  // Clear selection
  model.clearSelection();
  EXPECT_EQ(model.selectedCount(), 0);
  EXPECT_FALSE(model.isSelected(0));

  // Select range
  model.selectRange(0, 1);
  EXPECT_EQ(model.selectedCount(), 2);
  EXPECT_TRUE(model.isSelected(0));
  EXPECT_TRUE(model.isSelected(1));
  EXPECT_FALSE(model.isSelected(2));
  model.clearSelection();

  // Get selected tracks and remove
  model.setRowSelected(1, true);
  auto selectedIds = model.getSelectedTrackIds();
  EXPECT_EQ(selectedIds.size(), 1);
  EXPECT_EQ(selectedIds[0].toString(), "t2");

  model.removeSelected();
  EXPECT_EQ(model.rowCount(), 2);
  EXPECT_EQ(model.selectedCount(), 0);
}

TEST_F(SettingsTest, FileAndEditMenuActions) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;

  QtBridge bridge(player, library, &themeLoader);

  // Undo / Redo initial state
  EXPECT_FALSE(bridge.canUndo());
  EXPECT_FALSE(bridge.canRedo());

  // Push custom command
  bool commandExecuted = false;
  bridge.pushUndoCommand(
      "Test Action", [&commandExecuted]() { commandExecuted = false; },
      [&commandExecuted]() { commandExecuted = true; });

  EXPECT_TRUE(bridge.canUndo());
  EXPECT_FALSE(bridge.canRedo());
  EXPECT_EQ(bridge.undoActionName(), "Test Action");

  bridge.undo();
  EXPECT_FALSE(bridge.canUndo());
  EXPECT_TRUE(bridge.canRedo());
  EXPECT_EQ(bridge.redoActionName(), "Test Action");

  bridge.redo();
  EXPECT_TRUE(bridge.canUndo());
  EXPECT_FALSE(bridge.canRedo());

  // Export Active View
  core::Track t;
  t.id = "test_export";
  t.title = "Export Title";
  t.artist = "Export Artist";
  t.album = "Export Album";
  t.genre = "Test";
  t.year = 2024;
  t.trackNumber = 1;
  t.durationMs = 120000;
  t.filePath = "/tmp/test.flac";
  t.codec = "FLAC";
  t.bitrate = 1411;
  bridge.trackModel()->setTracks({t});

  QString m3u8Path = QDir::tempPath() + "/parakeet_test_export.m3u8";
  QString csvPath = QDir::tempPath() + "/parakeet_test_export.csv";
  QString jsonPath = QDir::tempPath() + "/parakeet_test_export.json";

  EXPECT_TRUE(bridge.exportActiveView(m3u8Path, "m3u8"));
  EXPECT_TRUE(QFile::exists(m3u8Path));
  QFile::remove(m3u8Path);

  EXPECT_TRUE(bridge.exportActiveView(csvPath, "csv"));
  EXPECT_TRUE(QFile::exists(csvPath));
  QFile::remove(csvPath);

  EXPECT_TRUE(bridge.exportActiveView(jsonPath, "json"));
  EXPECT_TRUE(QFile::exists(jsonPath));
  QFile::remove(jsonPath);

  // Network stream
  bridge.openNetworkStream("http://stream.example.com/audio.mp3",
                           "Example Radio");
  EXPECT_EQ(bridge.currentTrackTitle(), "Example Radio");

  // History Track Model
  EXPECT_NE(bridge.historyTrackModel(), nullptr);
  bridge.refreshHistory();
}

TEST_F(SettingsTest, PlaybackAndLibraryMenuActions) {
  auto audio = std::make_shared<tests::MockAudioEnginePort>();
  MockDb db;
  MockExtractor extractor;
  core::LibraryService library(db, extractor);
  core::PlayerService player(audio);
  adapters::ThemeLoader themeLoader;
  QtBridge bridge(player, library, &themeLoader);

  // Playback Rate
  bridge.setPlaybackRate(1.25);
  EXPECT_NEAR(bridge.playbackRate(), 1.25, 0.001);
  bridge.setPlaybackRate(0.5);
  EXPECT_NEAR(bridge.playbackRate(), 0.5, 0.001);
  bridge.setPlaybackRate(1.0);
  EXPECT_NEAR(bridge.playbackRate(), 1.0, 0.001);

  // A-B Looping
  EXPECT_FALSE(bridge.isLoopActive());
  bridge.setLoopPointA();
  EXPECT_GE(bridge.loopPointA(), 0);
  bridge.setLoopPointB();
  bridge.clearLoop();
  EXPECT_FALSE(bridge.isLoopActive());
  EXPECT_EQ(bridge.loopPointA(), -1);
  EXPECT_EQ(bridge.loopPointB(), -1);

  // Stop After Current Track
  EXPECT_FALSE(bridge.stopAfterCurrentTrack());
  bridge.toggleStopAfterCurrentTrack();
  EXPECT_TRUE(bridge.stopAfterCurrentTrack());
  bridge.toggleStopAfterCurrentTrack();
  EXPECT_FALSE(bridge.stopAfterCurrentTrack());

  // Sleep Timer
  EXPECT_FALSE(bridge.isSleepTimerActive());
  bridge.startSleepTimer(15);
  EXPECT_TRUE(bridge.isSleepTimerActive());
  EXPECT_EQ(bridge.sleepTimerRemainingSec(), 15 * 60);
  bridge.cancelSleepTimer();
  EXPECT_FALSE(bridge.isSleepTimerActive());
  EXPECT_EQ(bridge.sleepTimerRemainingSec(), 0);

  // Playlist creation
  EXPECT_TRUE(bridge.createPlaylist("Test_Favorites"));
  QString plPath =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
      "/playlists/Test_Favorites.m3u8";
  EXPECT_TRUE(QFile::exists(plPath));
  QFile::remove(plPath);

  // Smart Playlist creation
  EXPECT_TRUE(
      bridge.createSmartPlaylist("High_Bitrate", "{\"genre\":\"Rock\"}"));
  QString smartPath =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
      "/playlists/High_Bitrate.smart.json";
  EXPECT_TRUE(QFile::exists(smartPath));
  QFile::remove(smartPath);

  // Diagnostics
  auto diag = bridge.audioPipelineDiagnostics();
  EXPECT_TRUE(diag.contains("sampleRate"));
  EXPECT_TRUE(diag.contains("bitDepth"));
  EXPECT_TRUE(diag.contains("codec"));
  EXPECT_TRUE(diag.contains("audioBackend"));
  EXPECT_TRUE(diag.contains("isBitPerfect"));

  // Log file path
  QString logPath = bridge.getLogFilePath();
  EXPECT_TRUE(logPath.endsWith("parakeet.log"));
  EXPECT_TRUE(QFile::exists(logPath));

  // Deduplicate tracks
  core::Track t1;
  t1.id = "dup_1";
  t1.title = "Duplicate Song";
  t1.artist = "Duplicate Artist";
  t1.durationMs = 180000;

  core::Track t2;
  t2.id = "dup_2";
  t2.title = "Duplicate Song";
  t2.artist = "Duplicate Artist";
  t2.durationMs = 180000;

  db.saveTrack(t1);
  db.saveTrack(t2);

  int removed = bridge.deduplicateTracks();
  EXPECT_GE(removed, 1);
  EXPECT_TRUE(bridge.canUndo());
  bridge.undo();
  EXPECT_TRUE(bridge.canRedo());
  bridge.redo();
}
