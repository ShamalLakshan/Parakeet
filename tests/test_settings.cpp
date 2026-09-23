#include "QtBridge.hpp"
#include "core/ports/IMetadataExtractor.hpp"
#include "core/ports/IMusicDatabasePort.hpp"
#include "core/services/LibraryService.hpp"
#include "core/services/PlayerService.hpp"
#include "mocks/MockAudioEnginePort.hpp"
#include <QCoreApplication>
#include <QSettings>
#include <gtest/gtest.h>

namespace {

class MockDb : public core::IMusicDatabasePort {
public:
  bool initialize(const std::string &) override { return true; }
  bool saveTrack(const core::Track &) override { return true; }
  bool saveTracks(const std::vector<core::Track> &) override { return true; }
  std::optional<core::Track> getTrackById(const std::string &) override {
    return std::nullopt;
  }
  std::optional<core::Track> getTrackByPath(const std::string &) override {
    return std::nullopt;
  }
  std::vector<core::Track> getAllTracks() override { return {}; }
  std::vector<core::Track> getTracksByAlbum(const std::string &,
                                            const std::string &) override {
    return {};
  }
  bool deleteTrack(const std::string &) override { return true; }
  std::vector<core::Album> getAllAlbums() override { return {}; }
  std::optional<core::Album> getAlbumById(const std::string &) override {
    return std::nullopt;
  }
  bool clearLibrary() override { return true; }
  bool optimizeDatabase() override { return true; }
  size_t getTrackCount() override { return 0; }
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
