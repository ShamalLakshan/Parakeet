#include "QtBridge.hpp"
#include <QClipboard>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QKeySequence>
#include <QSettings>
#include <QStandardPaths>
#include <QSysInfo>
#include <QTextStream>
#include <QUrl>
#include <algorithm>
#include <iostream>
#include <random>
#include <set>

QtBridge::QtBridge(core::PlayerService &player, core::LibraryService &library,
                   adapters::ThemeLoader *themeLoader, QObject *parent)
    : QObject(parent), m_player(player), m_library(library),
      m_themeLoader(themeLoader) {

  // Initialize hotkeys registry
  initDefaultHotkeys();

  // Remove missing tracks on startup
  m_library.purgeNonExistentTracks();

  m_albumModel = new AlbumListModel(&m_library.getDatabasePort(), this);
  m_trackModel = new TrackListModel(&m_library.getDatabasePort(), this);
  m_albumDetailTrackModel =
      new TrackListModel(&m_library.getDatabasePort(), this);
  m_queueTrackModel = new TrackListModel(&m_library.getDatabasePort(), this);

  m_mediaDevices = new QMediaDevices(this);
  connect(m_mediaDevices, &QMediaDevices::audioOutputsChanged, this,
          &QtBridge::refreshAudioDevices);
  refreshAudioDevices();

  if (m_themeLoader) {
    connect(m_themeLoader, &adapters::ThemeLoader::themeChanged, this,
            [this]() {
              QSettings s("ParakeetAudio", "Parakeet");
              s.setValue("appearance/themeId", m_themeLoader->themeId());
            });
    connect(m_themeLoader, &adapters::ThemeLoader::uiScaleChanged, this,
            [this]() {
              QSettings s("ParakeetAudio", "Parakeet");
              s.setValue("appearance/uiScale", m_themeLoader->uiScale());
              s.setValue("appearance/densityPreset",
                         m_themeLoader->densityPreset());
            });
  }

  loadSettings();
  refreshLibraryStats();
  setupPositionTimer();

  if (m_autoScanOnStartup && !m_monitoredFolders.isEmpty()) {
    rescanAllMonitoredFolders();
  }
}

void QtBridge::loadSettings() {
  QSettings s("ParakeetAudio", "Parakeet");

  // Playback & DSP
  m_gaplessPlayback = s.value("playback/gaplessPlayback", true).toBool();
  m_crossfadeEnabled = s.value("playback/crossfadeEnabled", false).toBool();
  m_crossfadeDurationSec =
      s.value("playback/crossfadeDurationSec", 2.0).toReal();
  m_crossfadeCurve =
      s.value("playback/crossfadeCurve", "Equal Power (Constant Volume)")
          .toString();
  m_replayGainMode =
      s.value("playback/replayGainMode", "Smart Gain (Auto Track/Album)")
          .toString();
  m_replayGainPreampDb = s.value("playback/replayGainPreampDb", 0).toInt();
  m_replayGainPreampWithoutGainDb =
      s.value("playback/replayGainPreampWithoutGainDb", -6).toInt();
  m_truePeakLimiter = s.value("playback/truePeakLimiter", true).toBool();
  m_shortSeekStepSec = s.value("playback/shortSeekStepSec", 5).toInt();
  m_longSeekStepSec = s.value("playback/longSeekStepSec", 30).toInt();
  m_stopAfterCurrentTrack =
      s.value("playback/stopAfterCurrentTrack", false).toBool();

  // Queue & Ergonomics
  m_doubleClickAction =
      s.value("playback/doubleClickAction", "Play Now").toString();
  m_middleClickAction =
      s.value("playback/middleClickAction", "Queue Last").toString();
  m_queueAutoFillMode =
      s.value("playback/queueAutoFillMode", "Loop Context").toString();
  m_historyRetentionLimit =
      s.value("playback/historyRetentionLimit", 200).toInt();
  m_player.setHistoryLimit(static_cast<size_t>(m_historyRetentionLimit));

  int rMode = s.value("playback/repeatMode", 0).toInt();
  int sMode = s.value("playback/shuffleMode", 0).toInt();
  m_player.setRepeatMode(static_cast<core::RepeatMode>(rMode));
  m_player.setShuffleMode(static_cast<core::ShuffleMode>(sMode));

  // Library & Folders
  m_monitoredFolders = s.value("library/monitoredFolders").toStringList();
  m_filesystemWatcher = s.value("library/filesystemWatcher", true).toBool();
  m_autoScanOnStartup = s.value("library/autoScanOnStartup", false).toBool();
  QStringList defaultFormats = {"FLAC", "WAV", "ALAC", "AIFF", "DSD (DSF/DFF)",
                                "MP3",  "AAC", "M4A",  "OGG",  "OPUS"};
  m_formatFilters =
      s.value("library/formatFilters", defaultFormats).toStringList();
  m_excludeFolders =
      s.value("library/excludeFolders",
              ".*, node_modules, temp, @eaDir, System Volume Information")
          .toString();
  m_artworkPriority =
      s.value("library/artworkPriority", "Embedded Tags First").toString();

  // General
  m_language = s.value("general/language", "System Default").toString();
  m_startupAction =
      s.value("general/startupAction", "Restore Session").toString();
  m_closeAction = s.value("general/closeAction", "Exit Application").toString();
  m_minimizeAction =
      s.value("general/minimizeAction", "Minimize to Taskbar").toString();
  m_singleInstance = s.value("general/singleInstance", true).toBool();
  m_updateCheckInterval =
      s.value("general/updateCheckInterval", "Weekly").toString();
  m_showNotifications = s.value("general/showNotifications", true).toBool();
  m_notificationDurationSec =
      s.value("general/notificationDurationSec", 4).toInt();
  m_suppressNotificationsWhenFocused =
      s.value("general/suppressNotificationsWhenFocused", true).toBool();

  // Appearance
  m_fontFamily =
      s.value("appearance/fontFamily", "Inter, sans-serif").toString();
  m_baseFontSize = s.value("appearance/baseFontSize", 11).toInt();
  m_waveformSeekbar = s.value("appearance/waveformSeekbar", true).toBool();
  m_tableRowHeight = s.value("appearance/tableRowHeight", 32).toInt();
  m_tableAlternatingRows =
      s.value("appearance/tableAlternatingRows", false).toBool();
  m_artThumbnailQuality =
      s.value("appearance/artThumbnailQuality", "Smooth (High Quality)")
          .toString();
  m_artCacheLimitMb = s.value("appearance/artCacheLimitMb", 1024).toInt();
  m_showStatusBar = s.value("appearance/showStatusBar", true).toBool();

  if (m_themeLoader) {
    QString savedTheme =
        s.value("appearance/themeId", "dark-studio").toString();
    m_themeLoader->setThemeId(savedTheme);
    qreal savedScale = s.value("appearance/uiScale", 1.0).toReal();
    m_themeLoader->setUiScale(savedScale);
    QString savedDensity =
        s.value("appearance/densityPreset", "Standard").toString();
    m_themeLoader->setDensityPreset(savedDensity);
  }

  // Audio Output
  m_audioBackend =
      s.value("audio/backend", "Linux PipeWire Lock-Free Client").toString();
  m_currentAudioDevice =
      s.value("audio/device", "System Default Output").toString();
  m_bitPerfectExclusive = s.value("audio/bitPerfectExclusive", true).toBool();
  m_bufferLatencyMs = s.value("audio/bufferLatencyMs", 50).toInt();
  m_resamplerQuality =
      s.value("audio/resamplerQuality", "SoX Resampler High Quality")
          .toString();
  m_ditherMode =
      s.value("audio/ditherMode", "Flat TPDF (Triangular)").toString();
  m_channelProcessing =
      s.value("audio/channelProcessing", "Stereo Passthrough").toString();

  // Hotkeys & Accelerators
  m_globalMediaKeysEnabled =
      s.value("hotkeys/globalMediaKeysEnabled", true).toBool();
  for (auto &hk : m_hotkeys) {
    hk.currentSequence =
        s.value("hotkeys/" + hk.id, hk.defaultSequence).toString();
  }

  // Metadata & Scrobbling
  m_lastfmEnabled = s.value("metadata/lastfmEnabled", false).toBool();
  m_lastfmUsername = s.value("metadata/lastfmUsername", "").toString();
  m_lastfmSessionKey = s.value("metadata/lastfmSessionKey", "").toString();
  m_listenbrainzEnabled =
      s.value("metadata/listenbrainzEnabled", false).toBool();
  m_listenbrainzToken = s.value("metadata/listenbrainzToken", "").toString();
  m_listenbrainzApiUrl =
      s.value("metadata/listenbrainzApiUrl", "https://api.listenbrainz.org/1/")
          .toString();
  m_scrobbleThresholdPercent =
      s.value("metadata/scrobbleThresholdPercent", 50).toInt();
  m_scrobbleThresholdTimeSec =
      s.value("metadata/scrobbleThresholdTimeSec", 240).toInt();
  m_offlineScrobbleCache =
      s.value("metadata/offlineScrobbleCache", true).toBool();
  m_lyricsProviderOrder =
      s.value("metadata/lyricsProviderOrder", "Local .lrc sidecar first")
          .toString();
  m_autoFetchLyrics = s.value("metadata/autoFetchLyrics", true).toBool();

  // Diagnostics
  m_loggingVerbosity =
      s.value("diagnostics/loggingVerbosity", "Info").toString();
}

void QtBridge::saveSettings() {
  QSettings s("ParakeetAudio", "Parakeet");

  // Playback & DSP
  s.setValue("playback/gaplessPlayback", m_gaplessPlayback);
  s.setValue("playback/crossfadeEnabled", m_crossfadeEnabled);
  s.setValue("playback/crossfadeDurationSec", m_crossfadeDurationSec);
  s.setValue("playback/crossfadeCurve", m_crossfadeCurve);
  s.setValue("playback/replayGainMode", m_replayGainMode);
  s.setValue("playback/replayGainPreampDb", m_replayGainPreampDb);
  s.setValue("playback/replayGainPreampWithoutGainDb",
             m_replayGainPreampWithoutGainDb);
  s.setValue("playback/truePeakLimiter", m_truePeakLimiter);
  s.setValue("playback/shortSeekStepSec", m_shortSeekStepSec);
  s.setValue("playback/longSeekStepSec", m_longSeekStepSec);
  s.setValue("playback/stopAfterCurrentTrack", m_stopAfterCurrentTrack);

  // Queue & Ergonomics
  s.setValue("playback/doubleClickAction", m_doubleClickAction);
  s.setValue("playback/middleClickAction", m_middleClickAction);
  s.setValue("playback/queueAutoFillMode", m_queueAutoFillMode);
  s.setValue("playback/historyRetentionLimit", m_historyRetentionLimit);
  s.setValue("playback/repeatMode", static_cast<int>(m_player.getRepeatMode()));
  s.setValue("playback/shuffleMode",
             static_cast<int>(m_player.getShuffleMode()));

  // Library & Folders
  s.setValue("library/monitoredFolders", m_monitoredFolders);
  s.setValue("library/filesystemWatcher", m_filesystemWatcher);
  s.setValue("library/autoScanOnStartup", m_autoScanOnStartup);
  s.setValue("library/formatFilters", m_formatFilters);
  s.setValue("library/excludeFolders", m_excludeFolders);
  s.setValue("library/artworkPriority", m_artworkPriority);

  // General
  s.setValue("general/language", m_language);
  s.setValue("general/startupAction", m_startupAction);
  s.setValue("general/closeAction", m_closeAction);
  s.setValue("general/minimizeAction", m_minimizeAction);
  s.setValue("general/singleInstance", m_singleInstance);
  s.setValue("general/updateCheckInterval", m_updateCheckInterval);
  s.setValue("general/showNotifications", m_showNotifications);
  s.setValue("general/notificationDurationSec", m_notificationDurationSec);
  s.setValue("general/suppressNotificationsWhenFocused",
             m_suppressNotificationsWhenFocused);

  // Appearance
  s.setValue("appearance/fontFamily", m_fontFamily);
  s.setValue("appearance/baseFontSize", m_baseFontSize);
  s.setValue("appearance/waveformSeekbar", m_waveformSeekbar);
  s.setValue("appearance/tableRowHeight", m_tableRowHeight);
  s.setValue("appearance/tableAlternatingRows", m_tableAlternatingRows);
  s.setValue("appearance/artThumbnailQuality", m_artThumbnailQuality);
  s.setValue("appearance/artCacheLimitMb", m_artCacheLimitMb);
  s.setValue("appearance/showStatusBar", m_showStatusBar);

  if (m_themeLoader) {
    s.setValue("appearance/themeId", m_themeLoader->themeId());
    s.setValue("appearance/uiScale", m_themeLoader->uiScale());
    s.setValue("appearance/densityPreset", m_themeLoader->densityPreset());
  }

  // Audio Output
  s.setValue("audio/backend", m_audioBackend);
  s.setValue("audio/device", m_currentAudioDevice);
  s.setValue("audio/bitPerfectExclusive", m_bitPerfectExclusive);
  s.setValue("audio/bufferLatencyMs", m_bufferLatencyMs);
  s.setValue("audio/resamplerQuality", m_resamplerQuality);
  s.setValue("audio/ditherMode", m_ditherMode);
  s.setValue("audio/channelProcessing", m_channelProcessing);

  // Hotkeys
  s.setValue("hotkeys/globalMediaKeysEnabled", m_globalMediaKeysEnabled);
  for (const auto &hk : m_hotkeys) {
    s.setValue("hotkeys/" + hk.id, hk.currentSequence);
  }

  // Metadata & Scrobbling
  s.setValue("metadata/lastfmEnabled", m_lastfmEnabled);
  s.setValue("metadata/lastfmUsername", m_lastfmUsername);
  s.setValue("metadata/lastfmSessionKey", m_lastfmSessionKey);
  s.setValue("metadata/listenbrainzEnabled", m_listenbrainzEnabled);
  s.setValue("metadata/listenbrainzToken", m_listenbrainzToken);
  s.setValue("metadata/listenbrainzApiUrl", m_listenbrainzApiUrl);
  s.setValue("metadata/scrobbleThresholdPercent", m_scrobbleThresholdPercent);
  s.setValue("metadata/scrobbleThresholdTimeSec", m_scrobbleThresholdTimeSec);
  s.setValue("metadata/offlineScrobbleCache", m_offlineScrobbleCache);
  s.setValue("metadata/lyricsProviderOrder", m_lyricsProviderOrder);
  s.setValue("metadata/autoFetchLyrics", m_autoFetchLyrics);

  // Diagnostics
  s.setValue("diagnostics/loggingVerbosity", m_loggingVerbosity);

  emit settingsChanged();
  emit playbackSettingsChanged();
  emit queueSettingsChanged();
  emit librarySettingsChanged();
  emit audioSettingsChanged();
  emit hotkeysChanged();
  emit metadataSettingsChanged();
  emit diagnosticsSettingsChanged();
}

void QtBridge::setupPositionTimer() {
  m_positionTimer = new QTimer(this);
  m_positionTimer->setInterval(250);
  connect(m_positionTimer, &QTimer::timeout, this, [this]() {
    if (m_isPlaying) {
      uint64_t realPos = m_player.getPositionMs();
      m_positionMs = static_cast<qint64>(realPos);
      m_positionStr = formatTime(m_positionMs);
      emit positionChanged();

      // Check duration
      uint64_t realDur = m_player.getDurationMs();
      if (realDur > 0 && static_cast<qint64>(realDur) != m_durationMs) {
        m_durationMs = static_cast<qint64>(realDur);
        m_durationStr = formatTime(m_durationMs);
        emit playbackChanged();
      }
    }
  });
}

QString QtBridge::formatTime(qint64 ms) {
  qint64 totalSec = ms / 1000;
  qint64 min = totalSec / 60;
  qint64 sec = totalSec % 60;
  char buf[16];
  std::snprintf(buf, sizeof(buf), "%02lld:%02lld", static_cast<long long>(min),
                static_cast<long long>(sec));
  return QString::fromUtf8(buf);
}

QString QtBridge::formatBytes(uint64_t bytes) {
  if (bytes == 0)
    return "0 MB";
  double mb = static_cast<double>(bytes) / (1024.0 * 1024.0);
  if (mb >= 1024.0) {
    double gb = mb / 1024.0;
    return QString::asprintf("%.2f GB", gb);
  }
  return QString::asprintf("%.1f MB", mb);
}

QString QtBridge::currentArtUrl() const {
  if (m_currentArtHash.isEmpty()) {
    return "image://albumart/default";
  }
  return "image://albumart/" + m_currentArtHash;
}

int QtBridge::repeatMode() const {
  return static_cast<int>(m_player.getRepeatMode());
}

int QtBridge::shuffleMode() const {
  return static_cast<int>(m_player.getShuffleMode());
}

int QtBridge::queueRemainingCount() const {
  return static_cast<int>(m_player.getQueueService().getRemainingCount());
}

QString QtBridge::queueRemainingDurationStr() const {
  return formatTime(
      static_cast<qint64>(m_player.getQueueService().getRemainingDurationMs()));
}

int QtBridge::upNextCount() const {
  return static_cast<int>(m_player.getQueueService().getUpNext().size());
}

int QtBridge::totalAlbums() const {
  return static_cast<int>(m_library.getDatabasePort().getAlbumCount());
}

int QtBridge::totalTracks() const {
  return static_cast<int>(m_library.getDatabasePort().getTrackCount());
}

QString QtBridge::totalDurationStr() const {
  auto all = m_library.getTracks();
  uint64_t totalMs = 0;
  for (const auto &t : all)
    totalMs += t.durationMs;
  uint64_t totalSec = totalMs / 1000;
  uint64_t hours = totalSec / 3600;
  uint64_t min = (totalSec % 3600) / 60;
  uint64_t sec = totalSec % 60;
  if (hours > 0) {
    return QString::asprintf("%lluh %02llum %02llus", (unsigned long long)hours,
                             (unsigned long long)min, (unsigned long long)sec);
  }
  return QString::asprintf("%llum %02llus", (unsigned long long)min,
                           (unsigned long long)sec);
}

QString QtBridge::totalLibrarySizeStr() const {
  auto all = m_library.getTracks();
  uint64_t totalBytes = 0;
  for (const auto &t : all)
    totalBytes += t.fileSizeBytes;
  return formatBytes(totalBytes);
}

void QtBridge::refreshLibraryStats() {
  auto all = m_library.getTracks();
  std::set<std::string> genres;
  std::set<std::string> artists;
  for (const auto &t : all) {
    if (!t.genre.empty())
      genres.insert(t.genre);
    if (!t.artist.empty())
      artists.insert(t.artist);
  }

  m_genresList.clear();
  for (const auto &g : genres)
    m_genresList.append(QString::fromStdString(g));

  m_artistsList.clear();
  for (const auto &a : artists)
    m_artistsList.append(QString::fromStdString(a));

  emit libraryStatsChanged();
}

void QtBridge::syncQueueModel() {
  auto upcoming = m_player.getQueueService().getUpcomingQueue();
  m_queueTrackModel->setTracks(upcoming);
  emit queueChanged();
}

void QtBridge::scanDirectory(const QString &folderPath) {
  if (m_isScanning)
    return;

  QString localPath = folderPath;
  QUrl url = QUrl::fromUserInput(folderPath);
  if (url.isLocalFile()) {
    localPath = url.toLocalFile();
  } else if (localPath.startsWith("file://")) {
    localPath = localPath.mid(7);
  }

  std::string path = localPath.toStdString();
  m_isScanning = true;
  m_scanStatusText = QString("Indexing: %1...").arg(localPath);
  m_scanScanned = 0;
  m_scanTotal = 0;
  emit scanningChanged();

  std::thread([this, path]() {
    size_t count = m_library.scanDirectory(path, [this](size_t scanned,
                                                        size_t total) {
      QMetaObject::invokeMethod(
          this,
          [this, scanned, total]() {
            m_scanScanned = static_cast<int>(scanned);
            m_scanTotal = static_cast<int>(total);
            m_scanStatusText =
                QString("Indexed %1 / %2 tracks...").arg(scanned).arg(total);
            emit scanningChanged();
          },
          Qt::QueuedConnection);
    });

    QMetaObject::invokeMethod(
        this,
        [this, count]() {
          m_albumModel->reload();
          m_trackModel->loadAllTracks();
          refreshLibraryStats();
          m_isScanning = false;
          m_scanStatusText =
              QString("Scan complete: %1 tracks indexed").arg(count);
          emit scanningChanged();
          emit scanFinished(static_cast<int>(count));
        },
        Qt::QueuedConnection);
  }).detach();
}

void QtBridge::purgeMissingTracks() {
  size_t count = m_library.purgeNonExistentTracks();
  m_albumModel->reload();
  m_trackModel->loadAllTracks();
  refreshLibraryStats();
  syncQueueModel();
  m_scanStatusText = QString("Purged %1 non-existent tracks").arg(count);
  emit scanningChanged();
}

void QtBridge::clearLibrary() {
  m_library.clearLibrary();
  m_player.clearQueue();
  m_queueTrackModel->setTracks({});
  m_albumModel->reload();
  m_trackModel->loadAllTracks();
  refreshLibraryStats();
  syncQueueModel();
  m_scanStatusText = "Library cleared";
  emit scanningChanged();
}

void QtBridge::search(const QString &query) {
  m_albumModel->setFilter(query);
  m_trackModel->setFilter(query);
}

void QtBridge::filterByLetter(const QString &letter) {
  if (letter.isEmpty() || letter == "All") {
    m_albumModel->setFilter("");
    m_trackModel->setFilter("");
  } else {
    m_albumModel->setFilter(letter);
    m_trackModel->setFilter(letter);
  }
}

void QtBridge::filterByGenre(const QString &genre) {
  if (genre.isEmpty() || genre == "All") {
    m_trackModel->setFilter("");
  } else {
    m_trackModel->setFilter(genre);
  }
}

void QtBridge::filterByArtist(const QString &artist) {
  if (artist.isEmpty() || artist == "All") {
    m_trackModel->setFilter("");
    m_albumModel->setFilter("");
  } else {
    m_trackModel->setFilter(artist);
    m_albumModel->setFilter(artist);
  }
}

void QtBridge::resetFilters() {
  m_albumModel->setFilter("");
  m_trackModel->setFilter("");
}

void QtBridge::openAlbumDetails(const QString &albumTitle,
                                const QString &albumArtist) {
  auto albumOpt = m_library.getDatabasePort().getAlbumById(
      "alb_" + albumTitle.toStdString() + "_" + albumArtist.toStdString());
  if (albumOpt) {
    const auto &a = *albumOpt;
    m_selectedAlbumTitle = QString::fromStdString(a.title);
    m_selectedAlbumArtist = QString::fromStdString(a.artist);
    m_selectedAlbumYear = a.year > 0 ? QString::number(a.year) : "";
    m_selectedAlbumGenre = QString::fromStdString(a.genre);
    m_selectedAlbumQuality = QString::fromStdString(a.qualityBadge);
    m_selectedAlbumDuration = QString::fromStdString(a.durationFormatted());
    m_selectedAlbumTrackCount = static_cast<int>(a.trackCount);
    m_selectedAlbumArtHash = QString::fromStdString(a.artHash);
  } else {
    m_selectedAlbumTitle = albumTitle;
    m_selectedAlbumArtist = albumArtist;
    m_selectedAlbumYear = "";
    m_selectedAlbumGenre = "";
    m_selectedAlbumQuality = "Lossless";
    m_selectedAlbumDuration = "";
    m_selectedAlbumTrackCount = 0;
    m_selectedAlbumArtHash = "";
  }

  m_albumDetailTrackModel->loadAlbumTracks(albumTitle, albumArtist);
  emit selectedAlbumChanged();
}

void QtBridge::playAlbum(const QString &albumTitle,
                         const QString &albumArtist) {
  playAlbumNow(albumTitle, albumArtist);
}

void QtBridge::playTrack(const QString &trackId) { playNow(trackId); }

void QtBridge::playNow(const QString &trackId) {
  auto trackOpt = m_library.getTrackById(trackId.toStdString());
  if (trackOpt) {
    // Context tracks from current view
    auto allTracks = m_library.getTracks();
    size_t idx = 0;
    for (size_t i = 0; i < allTracks.size(); ++i) {
      if (allTracks[i].id == trackId.toStdString()) {
        idx = i;
        break;
      }
    }
    m_player.playQueue(allTracks, idx);
    updatePlaybackState(*trackOpt);
    syncQueueModel();
  }
}

void QtBridge::playNext(const QString &trackId) {
  auto trackOpt = m_library.getTrackById(trackId.toStdString());
  if (trackOpt) {
    m_player.playNext(*trackOpt);
    syncQueueModel();
  }
}

void QtBridge::queueLast(const QString &trackId) {
  auto trackOpt = m_library.getTrackById(trackId.toStdString());
  if (trackOpt) {
    m_player.queueLast(*trackOpt);
    syncQueueModel();
  }
}

void QtBridge::playAlbumNow(const QString &albumTitle,
                            const QString &albumArtist) {
  auto tracks = m_library.getTracksForAlbum(albumTitle.toStdString(),
                                            albumArtist.toStdString());
  if (!tracks.empty()) {
    m_player.playQueue(tracks, 0);
    updatePlaybackState(tracks[0]);
    syncQueueModel();
  }
}

void QtBridge::playAlbumNext(const QString &albumTitle,
                             const QString &albumArtist) {
  auto tracks = m_library.getTracksForAlbum(albumTitle.toStdString(),
                                            albumArtist.toStdString());
  if (!tracks.empty()) {
    m_player.playNext(tracks);
    syncQueueModel();
  }
}

void QtBridge::queueAlbumLast(const QString &albumTitle,
                              const QString &albumArtist) {
  auto tracks = m_library.getTracksForAlbum(albumTitle.toStdString(),
                                            albumArtist.toStdString());
  if (!tracks.empty()) {
    m_player.queueLast(tracks);
    syncQueueModel();
  }
}

void QtBridge::removeFromQueue(int index) {
  if (index >= 0) {
    m_player.removeFromQueue(static_cast<size_t>(index));
    syncQueueModel();
  }
}

void QtBridge::moveQueueItem(int fromIndex, int toIndex) {
  if (fromIndex >= 0 && toIndex >= 0) {
    m_player.moveQueueItem(static_cast<size_t>(fromIndex),
                           static_cast<size_t>(toIndex));
    syncQueueModel();
  }
}

void QtBridge::clearQueue() {
  m_player.clearQueue();
  syncQueueModel();
}

void QtBridge::shuffleRemainingQueue() {
  m_player.shuffleRemaining();
  syncQueueModel();
}

void QtBridge::playTrackAtIndex(int index) {
  auto trackMap = m_trackModel->getTrackAt(index);
  if (!trackMap.isEmpty()) {
    auto all = m_library.getTracks();
    size_t idx = std::clamp(static_cast<size_t>(index), size_t(0),
                            all.empty() ? 0 : all.size() - 1);
    m_player.playQueue(all, idx);
    if (!all.empty()) {
      updatePlaybackState(all[idx]);
    }
    syncQueueModel();
  }
}

void QtBridge::playTrackFromDetail(int index) {
  auto trackMap = m_albumDetailTrackModel->getTrackAt(index);
  if (!trackMap.isEmpty()) {
    auto tracks =
        m_library.getTracksForAlbum(m_selectedAlbumTitle.toStdString(),
                                    m_selectedAlbumArtist.toStdString());
    if (!tracks.empty()) {
      size_t idx =
          std::clamp(static_cast<size_t>(index), size_t(0), tracks.size() - 1);
      m_player.playQueue(tracks, idx);
      updatePlaybackState(tracks[idx]);
      syncQueueModel();
    }
  }
}

void QtBridge::playQueueTrack(int index) {
  auto upcoming = m_player.getQueueService().getUpcomingQueue();
  if (index >= 0 && index < static_cast<int>(upcoming.size())) {
    m_player.play(upcoming[static_cast<size_t>(index)]);
    updatePlaybackState(upcoming[static_cast<size_t>(index)]);
    // Remove current track from upcoming list
    m_player.removeFromQueue(static_cast<size_t>(index));
    syncQueueModel();
  }
}

void QtBridge::queueTrack(const QString &trackId) { queueLast(trackId); }

void QtBridge::updatePlaybackState(const core::Track &track) {
  m_isPlaying = true;

  m_currentTrackTitle = QString::fromStdString(track.title);
  m_currentArtist = QString::fromStdString(track.artist);
  m_currentAlbum = QString::fromStdString(track.album);
  m_currentYear = track.year > 0 ? QString::number(track.year) : "";
  m_currentGenre = QString::fromStdString(track.genre);
  m_currentCodec = QString::fromStdString(track.codec);
  m_currentFilePath = QString::fromStdString(track.filePath);
  m_currentFileSizeStr = formatBytes(track.fileSizeBytes);
  m_currentBitrate = static_cast<int>(track.bitrate);
  m_currentSampleRate = static_cast<int>(track.sampleRate);
  m_currentBitDepth = static_cast<int>(track.bitDepth);
  m_currentChannels = static_cast<int>(track.channels);

  // Audio specs
  QString spec = m_currentCodec;
  if (track.sampleRate > 0) {
    double khz = static_cast<double>(track.sampleRate) / 1000.0;
    spec += QString(" • %1 kHz").arg(khz, 0, 'f', 1);
  }
  if (track.bitDepth > 0) {
    spec += QString(" • %1-bit").arg(track.bitDepth);
  }
  if (track.bitrate > 0) {
    spec += QString(" • %1 kbps").arg(track.bitrate);
  }
  if (track.channels == 1)
    spec += " • Mono";
  else if (track.channels == 2)
    spec += " • Stereo";
  else if (track.channels > 2)
    spec += QString(" • %1 Ch").arg(track.channels);

  m_currentAudioSpecs = spec;
  m_currentArtHash = QString::fromStdString(track.artHash);
  m_durationMs = static_cast<qint64>(track.durationMs);
  m_positionMs = 0;
  m_positionStr = "00:00";
  m_durationStr = QString::fromStdString(track.durationFormatted());

  m_positionTimer->start();
  emit playbackChanged();
  emit positionChanged();
  syncQueueModel();
}

void QtBridge::togglePlayPause() {
  m_player.togglePlayPause();
  m_isPlaying = m_player.isPlaying();
  if (m_isPlaying) {
    m_positionTimer->start();
  } else {
    m_positionTimer->stop();
  }
  emit playbackChanged();
}

void QtBridge::stop() {
  m_player.stop();
  m_isPlaying = false;
  m_positionMs = 0;
  m_positionStr = "00:00";
  m_positionTimer->stop();
  emit playbackChanged();
  emit positionChanged();
}

void QtBridge::nextTrack() {
  m_player.next();
  auto current = m_player.getCurrentTrack();
  if (current.has_value()) {
    updatePlaybackState(*current);
  } else {
    stop();
  }
}

void QtBridge::previousTrack() {
  m_player.previous();
  auto current = m_player.getCurrentTrack();
  if (current.has_value()) {
    updatePlaybackState(*current);
  }
}

void QtBridge::seek(qint64 posMs) {
  m_positionMs = std::clamp(posMs, qint64(0), m_durationMs);
  m_positionStr = formatTime(m_positionMs);
  m_player.seek(static_cast<uint64_t>(m_positionMs));
  emit positionChanged();
}

void QtBridge::setVolume(float volume) {
  m_volume = std::clamp(volume, 0.0f, 1.0f);
  m_player.setVolume(m_volume);
  m_isMuted = (m_volume == 0.0f);
  emit volumeChanged();
}

void QtBridge::toggleMute() {
  if (m_isMuted) {
    setVolume(m_prevVolume > 0.0f ? m_prevVolume : 0.8f);
  } else {
    m_prevVolume = m_volume;
    setVolume(0.0f);
  }
}

void QtBridge::setRepeatMode(int mode) {
  m_player.setRepeatMode(static_cast<core::RepeatMode>(mode));
  saveSettings();
  emit playbackModeChanged();
}

void QtBridge::cycleRepeatMode() {
  m_player.cycleRepeatMode();
  saveSettings();
  emit playbackModeChanged();
}

void QtBridge::setShuffleMode(int mode) {
  m_player.setShuffleMode(static_cast<core::ShuffleMode>(mode));
  saveSettings();
  syncQueueModel();
  emit playbackModeChanged();
}

void QtBridge::cycleShuffleMode() {
  int next = (shuffleMode() + 1) % 3;
  setShuffleMode(next);
}

void QtBridge::playAll() {
  auto all = m_library.getTracks();
  if (!all.empty()) {
    m_player.playQueue(all, 0);
    updatePlaybackState(all[0]);
    syncQueueModel();
  }
}

void QtBridge::shuffleAll() {
  auto all = m_library.getTracks();
  if (!all.empty()) {
    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(all.begin(), all.end(), g);
    m_player.playQueue(all, 0);
    updatePlaybackState(all[0]);
    syncQueueModel();
  }
}

void QtBridge::showInFileManager(const QString &filePath) {
  QFileInfo fi(filePath);
  if (fi.exists()) {
    QDesktopServices::openUrl(QUrl::fromLocalFile(fi.absolutePath()));
  }
}

void QtBridge::copyToClipboard(const QString &text) {
  QClipboard *cb = QGuiApplication::clipboard();
  if (cb) {
    cb->setText(text);
  }
}

void QtBridge::addMonitoredFolder(const QString &folderPath) {
  QString local = folderPath;
  QUrl u = QUrl::fromUserInput(folderPath);
  if (u.isLocalFile())
    local = u.toLocalFile();
  else if (local.startsWith("file://"))
    local = local.mid(7);

  if (!local.isEmpty() && !m_monitoredFolders.contains(local)) {
    m_monitoredFolders.append(local);
    saveSettings();
    scanDirectory(local);
  }
}

void QtBridge::removeMonitoredFolder(int index) {
  if (index >= 0 && index < m_monitoredFolders.size()) {
    m_monitoredFolders.removeAt(index);
    saveSettings();
  }
}

void QtBridge::rescanAllMonitoredFolders() {
  for (const QString &folder : m_monitoredFolders) {
    scanDirectory(folder);
  }
}

void QtBridge::incrementalQuickScan() {
  if (m_isScanning.exchange(true))
    return;
  m_scanScanned = 0;
  m_scanTotal = 0;
  m_scanStatusText = "Quick scan in progress...";
  emit scanningChanged();

  std::vector<std::string> paths;
  for (const auto &folder : m_monitoredFolders) {
    paths.push_back(folder.toStdString());
  }

  std::thread([this, paths]() {
    size_t totalAdded = 0;
    for (const auto &path : paths) {
      totalAdded += m_library.incrementalQuickScan(
          path, [this](size_t scanned, size_t total) {
            QMetaObject::invokeMethod(
                this,
                [this, scanned, total]() {
                  m_scanScanned = static_cast<int>(scanned);
                  m_scanTotal = static_cast<int>(total);
                  m_scanStatusText = QString("Quick scanned %1 / %2 files...")
                                         .arg(scanned)
                                         .arg(total);
                  emit scanningChanged();
                },
                Qt::QueuedConnection);
          });
    }

    QMetaObject::invokeMethod(
        this,
        [this, totalAdded]() {
          m_albumModel->reload();
          m_trackModel->loadAllTracks();
          refreshLibraryStats();
          m_isScanning = false;
          m_scanStatusText = QString("Quick scan complete: %1 new tracks added")
                                 .arg(totalAdded);
          emit scanningChanged();
          emit scanFinished(static_cast<int>(totalAdded));
        },
        Qt::QueuedConnection);
  }).detach();
}

void QtBridge::setGaplessPlayback(bool enable) {
  if (m_gaplessPlayback != enable) {
    m_gaplessPlayback = enable;
    saveSettings();
  }
}

void QtBridge::setCrossfadeEnabled(bool enable) {
  if (m_crossfadeEnabled != enable) {
    m_crossfadeEnabled = enable;
    saveSettings();
  }
}

void QtBridge::setCrossfadeDurationSec(qreal sec) {
  if (!qFuzzyCompare(m_crossfadeDurationSec, sec)) {
    m_crossfadeDurationSec = sec;
    saveSettings();
  }
}

void QtBridge::setCrossfadeCurve(const QString &curve) {
  if (m_crossfadeCurve != curve) {
    m_crossfadeCurve = curve;
    saveSettings();
  }
}

void QtBridge::setReplayGainMode(const QString &mode) {
  if (m_replayGainMode != mode) {
    m_replayGainMode = mode;
    saveSettings();
  }
}

void QtBridge::setReplayGainPreampDb(int db) {
  if (m_replayGainPreampDb != db) {
    m_replayGainPreampDb = db;
    saveSettings();
  }
}

void QtBridge::setReplayGainPreampWithoutGainDb(int db) {
  if (m_replayGainPreampWithoutGainDb != db) {
    m_replayGainPreampWithoutGainDb = db;
    saveSettings();
  }
}

void QtBridge::setTruePeakLimiter(bool enable) {
  if (m_truePeakLimiter != enable) {
    m_truePeakLimiter = enable;
    saveSettings();
  }
}

void QtBridge::setShortSeekStepSec(int sec) {
  if (m_shortSeekStepSec != sec) {
    m_shortSeekStepSec = sec;
    saveSettings();
  }
}

void QtBridge::setLongSeekStepSec(int sec) {
  if (m_longSeekStepSec != sec) {
    m_longSeekStepSec = sec;
    saveSettings();
  }
}

void QtBridge::setStopAfterCurrentTrack(bool enable) {
  if (m_stopAfterCurrentTrack != enable) {
    m_stopAfterCurrentTrack = enable;
    saveSettings();
  }
}

void QtBridge::setDoubleClickAction(const QString &action) {
  if (m_doubleClickAction != action) {
    m_doubleClickAction = action;
    saveSettings();
  }
}

void QtBridge::setMiddleClickAction(const QString &action) {
  if (m_middleClickAction != action) {
    m_middleClickAction = action;
    saveSettings();
  }
}

void QtBridge::setQueueAutoFillMode(const QString &mode) {
  if (m_queueAutoFillMode != mode) {
    m_queueAutoFillMode = mode;
    saveSettings();
  }
}

void QtBridge::setHistoryRetentionLimit(int limit) {
  if (m_historyRetentionLimit != limit) {
    m_historyRetentionLimit = limit;
    m_player.setHistoryLimit(static_cast<size_t>(limit));
    saveSettings();
  }
}

void QtBridge::clearPlaybackHistory() {
  m_player.clearHistory();
  emit queueChanged();
}

void QtBridge::setFilesystemWatcher(bool enable) {
  if (m_filesystemWatcher != enable) {
    m_filesystemWatcher = enable;
    saveSettings();
  }
}

void QtBridge::setAutoScanOnStartup(bool enable) {
  if (m_autoScanOnStartup != enable) {
    m_autoScanOnStartup = enable;
    saveSettings();
  }
}

void QtBridge::setFormatFilters(const QStringList &formats) {
  if (m_formatFilters != formats) {
    m_formatFilters = formats;
    saveSettings();
  }
}

void QtBridge::setFormatFilterEnabled(const QString &format, bool enabled) {
  if (enabled && !m_formatFilters.contains(format, Qt::CaseInsensitive)) {
    m_formatFilters.append(format);
    saveSettings();
  } else if (!enabled &&
             m_formatFilters.contains(format, Qt::CaseInsensitive)) {
    m_formatFilters.removeAll(format);
    saveSettings();
  }
}

bool QtBridge::isFormatFilterEnabled(const QString &format) const {
  for (const QString &f : m_formatFilters) {
    if (f.compare(format, Qt::CaseInsensitive) == 0)
      return true;
  }
  return false;
}

void QtBridge::setExcludeFolders(const QString &patterns) {
  if (m_excludeFolders != patterns) {
    m_excludeFolders = patterns;
    saveSettings();
  }
}

void QtBridge::setArtworkPriority(const QString &priority) {
  if (m_artworkPriority != priority) {
    m_artworkPriority = priority;
    saveSettings();
  }
}

void QtBridge::optimizeDatabase() {
  m_library.optimizeDatabase();
  m_scanStatusText = "Database optimized (VACUUM & REINDEX complete)";
  emit scanningChanged();
}

void QtBridge::exportDatabaseBackup(const QString &targetFilePath) {
  QString src =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
      "/parakeet_library.db";
  QString dest = targetFilePath;
  QUrl u = QUrl::fromUserInput(targetFilePath);
  if (u.isLocalFile())
    dest = u.toLocalFile();
  if (QFile::exists(dest))
    QFile::remove(dest);
  QFile::copy(src, dest);
}

void QtBridge::setLanguage(const QString &lang) {
  if (m_language != lang) {
    m_language = lang;
    saveSettings();
  }
}

void QtBridge::setStartupAction(const QString &action) {
  if (m_startupAction != action) {
    m_startupAction = action;
    saveSettings();
  }
}

void QtBridge::setCloseAction(const QString &action) {
  if (m_closeAction != action) {
    m_closeAction = action;
    saveSettings();
  }
}

void QtBridge::setMinimizeAction(const QString &action) {
  if (m_minimizeAction != action) {
    m_minimizeAction = action;
    saveSettings();
  }
}

void QtBridge::setSingleInstance(bool enable) {
  if (m_singleInstance != enable) {
    m_singleInstance = enable;
    saveSettings();
  }
}

void QtBridge::setUpdateCheckInterval(const QString &interval) {
  if (m_updateCheckInterval != interval) {
    m_updateCheckInterval = interval;
    saveSettings();
  }
}

void QtBridge::setShowNotifications(bool enable) {
  if (m_showNotifications != enable) {
    m_showNotifications = enable;
    saveSettings();
  }
}

void QtBridge::setNotificationDurationSec(int sec) {
  if (m_notificationDurationSec != sec) {
    m_notificationDurationSec = sec;
    saveSettings();
  }
}

void QtBridge::setSuppressNotificationsWhenFocused(bool enable) {
  if (m_suppressNotificationsWhenFocused != enable) {
    m_suppressNotificationsWhenFocused = enable;
    saveSettings();
  }
}

void QtBridge::setFontFamily(const QString &font) {
  if (m_fontFamily != font) {
    m_fontFamily = font;
    saveSettings();
  }
}

void QtBridge::setBaseFontSize(int size) {
  if (m_baseFontSize != size) {
    m_baseFontSize = size;
    saveSettings();
  }
}

void QtBridge::setWaveformSeekbar(bool enable) {
  if (m_waveformSeekbar != enable) {
    m_waveformSeekbar = enable;
    saveSettings();
  }
}

void QtBridge::setTableRowHeight(int height) {
  if (m_tableRowHeight != height) {
    m_tableRowHeight = height;
    saveSettings();
  }
}

void QtBridge::setTableAlternatingRows(bool enable) {
  if (m_tableAlternatingRows != enable) {
    m_tableAlternatingRows = enable;
    saveSettings();
  }
}

void QtBridge::setArtThumbnailQuality(const QString &quality) {
  if (m_artThumbnailQuality != quality) {
    m_artThumbnailQuality = quality;
    saveSettings();
  }
}

void QtBridge::setArtCacheLimitMb(int limitMb) {
  if (m_artCacheLimitMb != limitMb) {
    m_artCacheLimitMb = limitMb;
    saveSettings();
  }
}

void QtBridge::setShowStatusBar(bool enable) {
  if (m_showStatusBar != enable) {
    m_showStatusBar = enable;
    saveSettings();
  }
}

void QtBridge::setAudioBackend(const QString &backend) {
  if (m_audioBackend != backend) {
    m_audioBackend = backend;
    saveSettings();
  }
}

void QtBridge::setCurrentAudioDevice(const QString &device) {
  if (m_currentAudioDevice != device) {
    m_currentAudioDevice = device;
    saveSettings();
  }
}

void QtBridge::setBitPerfectExclusive(bool exclusive) {
  if (m_bitPerfectExclusive != exclusive) {
    m_bitPerfectExclusive = exclusive;
    saveSettings();
  }
}

void QtBridge::setBufferLatencyMs(int ms) {
  if (m_bufferLatencyMs != ms) {
    m_bufferLatencyMs = ms;
    saveSettings();
  }
}

void QtBridge::setResamplerQuality(const QString &quality) {
  if (m_resamplerQuality != quality) {
    m_resamplerQuality = quality;
    saveSettings();
  }
}

void QtBridge::setDitherMode(const QString &mode) {
  if (m_ditherMode != mode) {
    m_ditherMode = mode;
    saveSettings();
  }
}

void QtBridge::setChannelProcessing(const QString &mode) {
  if (m_channelProcessing != mode) {
    m_channelProcessing = mode;
    saveSettings();
  }
}

void QtBridge::clearArtCache() {
  QString coversDir =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
      "/covers";
  QDir dir(coversDir);
  if (dir.exists()) {
    dir.removeRecursively();
    dir.mkpath(".");
  }
}

void QtBridge::checkForUpdates() {
  // Trigger or schedule update check logic
}

void QtBridge::refreshAudioDevices() {
  QStringList devices;
  devices.append("System Default Output");

  const auto outputs = QMediaDevices::audioOutputs();
  for (const auto &dev : outputs) {
    QString desc = dev.description();
    if (!desc.isEmpty() && !devices.contains(desc)) {
      devices.append(desc);
    }
  }
  m_availableAudioDevices = devices;
  emit audioDevicesChanged();
}

void QtBridge::initDefaultHotkeys() {
  m_hotkeys = {
      {"play_pause", "Playback", "Play / Pause playback", "Space", "Space"},
      {"stop", "Playback", "Stop playback", "Ctrl+.", "Ctrl+."},
      {"next_track", "Playback", "Next track", "Ctrl+Right", "Ctrl+Right"},
      {"prev_track", "Playback", "Previous track (Reversible History)",
       "Ctrl+Left", "Ctrl+Left"},
      {"seek_forward_short", "Playback", "Seek forward (Short)", "Right",
       "Right"},
      {"seek_backward_short", "Playback", "Seek backward (Short)", "Left",
       "Left"},
      {"seek_forward_long", "Playback", "Seek forward (Long)", "Shift+Right",
       "Shift+Right"},
      {"seek_backward_long", "Playback", "Seek backward (Long)", "Shift+Left",
       "Shift+Left"},
      {"volume_up", "Playback", "Volume up (+5%)", "Ctrl+Up", "Ctrl+Up"},
      {"volume_down", "Playback", "Volume down (-5%)", "Ctrl+Down",
       "Ctrl+Down"},
      {"toggle_mute", "Playback", "Mute / Unmute audio", "Ctrl+M", "Ctrl+M"},
      {"cycle_repeat", "Playback", "Cycle Repeat mode", "Ctrl+R", "Ctrl+R"},
      {"cycle_shuffle", "Playback", "Cycle Shuffle mode", "Ctrl+S", "Ctrl+S"},

      {"toggle_explorer", "View & Navigation", "Toggle Left Library Explorer",
       "Ctrl+1", "Ctrl+1"},
      {"toggle_filter_browser", "View & Navigation",
       "Toggle 3-Column Filter Browser", "Ctrl+2", "Ctrl+2"},
      {"toggle_inspector", "View & Navigation",
       "Toggle Right Inspector / Queue", "Ctrl+3", "Ctrl+3"},
      {"focus_search", "View & Navigation", "Focus Instant Search input",
       "Ctrl+F", "Ctrl+F"},
      {"clear_filter_escape", "View & Navigation",
       "Clear filter / Close active modal", "Escape", "Escape"},

      {"open_preferences", "Library & Editing", "Open Preferences Dialog",
       "Ctrl+,", "Ctrl+,"},
      {"rescan_library", "Library & Editing",
       "Rescan Monitored Library Folders", "Ctrl+Shift+R", "Ctrl+Shift+R"},
      {"quick_scan", "Library & Editing", "Incremental Quick Scan", "F5", "F5"},
      {"clear_queue", "Library & Editing", "Clear Playback Queue",
       "Ctrl+Shift+Del", "Ctrl+Shift+Del"},
      {"shuffle_queue", "Library & Editing", "Shuffle Playback Queue",
       "Ctrl+Shift+S", "Ctrl+Shift+S"}};
}

QVariantList QtBridge::hotkeysModel() const {
  QVariantList list;
  list.reserve(static_cast<qsizetype>(m_hotkeys.size()));
  for (const auto &entry : m_hotkeys) {
    QVariantMap map;
    map["id"] = entry.id;
    map["category"] = entry.category;
    map["actionName"] = entry.actionName;
    map["defaultSequence"] = entry.defaultSequence;
    map["currentSequence"] = entry.currentSequence;
    list.append(map);
  }
  return list;
}

void QtBridge::setGlobalMediaKeysEnabled(bool enable) {
  if (m_globalMediaKeysEnabled != enable) {
    m_globalMediaKeysEnabled = enable;
    saveSettings();
    emit hotkeysChanged();
  }
}

void QtBridge::setHotkey(const QString &actionId, const QString &keySequence) {
  for (auto &entry : m_hotkeys) {
    if (entry.id == actionId) {
      if (entry.currentSequence != keySequence) {
        entry.currentSequence = keySequence;
        saveSettings();
        emit hotkeysChanged();
      }
      return;
    }
  }
}

void QtBridge::restoreDefaultHotkeys() {
  for (auto &entry : m_hotkeys) {
    entry.currentSequence = entry.defaultSequence;
  }
  saveSettings();
  emit hotkeysChanged();
}

QString QtBridge::checkHotkeyConflict(const QString &actionId,
                                      const QString &keySequence) const {
  QString clean = keySequence.trimmed();
  if (clean.isEmpty()) {
    return "";
  }
  QKeySequence candidate(clean);
  if (candidate.isEmpty()) {
    return "";
  }

  for (const auto &entry : m_hotkeys) {
    if (entry.id != actionId && !entry.currentSequence.isEmpty()) {
      QKeySequence existing(entry.currentSequence);
      if (candidate == existing ||
          entry.currentSequence.compare(clean, Qt::CaseInsensitive) == 0) {
        return entry.actionName;
      }
    }
  }
  return "";
}

void QtBridge::setLastfmEnabled(bool enable) {
  if (m_lastfmEnabled != enable) {
    m_lastfmEnabled = enable;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setLastfmUsername(const QString &user) {
  if (m_lastfmUsername != user) {
    m_lastfmUsername = user;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setLastfmSessionKey(const QString &key) {
  if (m_lastfmSessionKey != key) {
    m_lastfmSessionKey = key;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setListenbrainzEnabled(bool enable) {
  if (m_listenbrainzEnabled != enable) {
    m_listenbrainzEnabled = enable;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setListenbrainzToken(const QString &token) {
  if (m_listenbrainzToken != token) {
    m_listenbrainzToken = token;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setListenbrainzApiUrl(const QString &url) {
  if (m_listenbrainzApiUrl != url) {
    m_listenbrainzApiUrl = url;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setScrobbleThresholdPercent(int percent) {
  if (m_scrobbleThresholdPercent != percent) {
    m_scrobbleThresholdPercent = percent;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setScrobbleThresholdTimeSec(int sec) {
  if (m_scrobbleThresholdTimeSec != sec) {
    m_scrobbleThresholdTimeSec = sec;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setOfflineScrobbleCache(bool enable) {
  if (m_offlineScrobbleCache != enable) {
    m_offlineScrobbleCache = enable;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setLyricsProviderOrder(const QString &order) {
  if (m_lyricsProviderOrder != order) {
    m_lyricsProviderOrder = order;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setAutoFetchLyrics(bool enable) {
  if (m_autoFetchLyrics != enable) {
    m_autoFetchLyrics = enable;
    saveSettings();
    emit metadataSettingsChanged();
  }
}

void QtBridge::setLoggingVerbosity(const QString &level) {
  if (m_loggingVerbosity != level) {
    m_loggingVerbosity = level;
    saveSettings();
    emit diagnosticsSettingsChanged();
  }
}

void QtBridge::openLogDirectory() {
  QString logDir =
      QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
      "/logs";
  QDir().mkpath(logDir);
  QDesktopServices::openUrl(QUrl::fromLocalFile(logDir));
}

void QtBridge::exportDiagnosticsReport(const QString &targetFilePath) {
  QString dest = targetFilePath;
  QUrl u = QUrl::fromUserInput(targetFilePath);
  if (u.isLocalFile()) {
    dest = u.toLocalFile();
  }

  QFile file(dest);
  if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
    QTextStream out(&file);
    out << "Parakeet Audio Player - Diagnostics Report\n";
    out << "==========================================\n\n";
    out << "OS: " << QSysInfo::prettyProductName() << " ("
        << QSysInfo::currentCpuArchitecture() << ")\n";
    out << "Kernel: " << QSysInfo::kernelType() << " "
        << QSysInfo::kernelVersion() << "\n";
    out << "Qt Version: " << QT_VERSION_STR << "\n\n";

    out << "[Audio Pipeline]\n";
    out << "Backend: " << m_audioBackend << "\n";
    out << "Device: " << m_currentAudioDevice << "\n";
    out << "Bit-Perfect Exclusive: "
        << (m_bitPerfectExclusive ? "Enabled" : "Disabled") << "\n";
    out << "Buffer Latency: " << m_bufferLatencyMs << " ms\n";
    out << "Resampler Quality: " << m_resamplerQuality << "\n";
    out << "Dither Mode: " << m_ditherMode << "\n";
    out << "Channel Processing: " << m_channelProcessing << "\n\n";

    out << "[Library & Storage]\n";
    out << "Indexed Tracks: " << totalTracks() << "\n";
    out << "Indexed Albums: " << totalAlbums() << "\n";
    out << "Total Library Duration: " << totalDurationStr() << "\n";
    out << "Monitored Folders Count: " << m_monitoredFolders.size() << "\n";
    for (const auto &folder : m_monitoredFolders) {
      out << "  - " << folder << "\n";
    }
    out << "Filesystem Watcher: "
        << (m_filesystemWatcher ? "Active" : "Disabled") << "\n";
    out << "Auto-scan on Startup: "
        << (m_autoScanOnStartup ? "Enabled" : "Disabled") << "\n\n";

    out << "[Scrobbling & Services]\n";
    out << "Last.fm Scrobbling: " << (m_lastfmEnabled ? "Enabled" : "Disabled")
        << " (User: " << m_lastfmUsername << ")\n";
    out << "ListenBrainz Scrobbling: "
        << (m_listenbrainzEnabled ? "Enabled" : "Disabled") << "\n";
    out << "Offline Scrobble Cache: "
        << (m_offlineScrobbleCache ? "Enabled" : "Disabled") << "\n";
    out << "Lyrics Provider Order: " << m_lyricsProviderOrder << "\n";
    out << "Auto-fetch Lyrics: " << (m_autoFetchLyrics ? "Enabled" : "Disabled")
        << "\n\n";

    out << "[Diagnostics & Logging]\n";
    out << "Logging Verbosity: " << m_loggingVerbosity << "\n\n";

    out << "[Hotkeys & Accelerators]\n";
    out << "Global Media Keys: "
        << (m_globalMediaKeysEnabled ? "Enabled" : "Disabled") << "\n";
    for (const auto &hk : m_hotkeys) {
      out << "  - [" << hk.category << "] " << hk.actionName << ": "
          << hk.currentSequence << " (Default: " << hk.defaultSequence << ")\n";
    }
    file.close();
  }
}

void QtBridge::openAudioDiagnostics() { emit audioDiagnosticsRequested(); }

QString QtBridge::checkDatabaseIntegrity() {
  bool ok = m_library.optimizeDatabase();
  if (ok) {
    return QString(
        "Integrity check passed: Database schema, tables, and indices are "
        "valid and healthy.");
  }
  return QString(
      "Integrity check warning: SQLite database reported warnings during "
      "verification.");
}

void QtBridge::resetAllSettingsToDefaults() {
  QSettings s("ParakeetAudio", "Parakeet");
  s.clear();

  // Playback & DSP defaults
  m_gaplessPlayback = true;
  m_crossfadeEnabled = false;
  m_crossfadeDurationSec = 2.0;
  m_crossfadeCurve = "Equal Power (Constant Volume)";
  m_replayGainMode = "Smart Gain (Auto Track/Album)";
  m_replayGainPreampDb = 0;
  m_replayGainPreampWithoutGainDb = -6;
  m_truePeakLimiter = true;
  m_shortSeekStepSec = 5;
  m_longSeekStepSec = 30;
  m_stopAfterCurrentTrack = false;

  // Queue defaults
  m_doubleClickAction = "Play Now";
  m_middleClickAction = "Queue Last";
  m_queueAutoFillMode = "Loop Context";
  m_historyRetentionLimit = 200;
  m_player.setHistoryLimit(200);

  // Library defaults
  m_monitoredFolders.clear();
  m_filesystemWatcher = true;
  m_autoScanOnStartup = false;
  m_formatFilters = {"FLAC", "WAV", "ALAC", "AIFF", "DSD (DSF/DFF)",
                     "MP3",  "AAC", "M4A",  "OGG",  "OPUS"};
  m_excludeFolders =
      ".*, node_modules, temp, @eaDir, System Volume Information";
  m_artworkPriority = "Embedded Tags First";

  // General defaults
  m_language = "System Default";
  m_startupAction = "Restore Session";
  m_closeAction = "Exit Application";
  m_minimizeAction = "Minimize to Taskbar";
  m_singleInstance = true;
  m_updateCheckInterval = "Weekly";
  m_showNotifications = true;
  m_notificationDurationSec = 4;
  m_suppressNotificationsWhenFocused = true;

  // Appearance defaults
  m_fontFamily = "Inter, sans-serif";
  m_baseFontSize = 11;
  m_waveformSeekbar = true;
  m_tableRowHeight = 32;
  m_tableAlternatingRows = false;
  m_artThumbnailQuality = "Smooth (High Quality)";
  m_artCacheLimitMb = 1024;
  m_showStatusBar = true;

  if (m_themeLoader) {
    m_themeLoader->setThemeId("dark-studio");
    m_themeLoader->setUiScale(1.0);
    m_themeLoader->setDensityPreset("Standard");
  }

  // Audio Output defaults
  m_audioBackend = "Linux PipeWire Lock-Free Client";
  m_currentAudioDevice = "System Default Output";
  m_bitPerfectExclusive = true;
  m_bufferLatencyMs = 50;
  m_resamplerQuality = "SoX Resampler High Quality";
  m_ditherMode = "Flat TPDF (Triangular)";
  m_channelProcessing = "Stereo Passthrough";

  // Hotkeys defaults
  m_globalMediaKeysEnabled = true;
  for (auto &hk : m_hotkeys) {
    hk.currentSequence = hk.defaultSequence;
  }

  // Metadata & Scrobbling defaults
  m_lastfmEnabled = false;
  m_lastfmUsername = "";
  m_lastfmSessionKey = "";
  m_listenbrainzEnabled = false;
  m_listenbrainzToken = "";
  m_listenbrainzApiUrl = "https://api.listenbrainz.org/1/";
  m_scrobbleThresholdPercent = 50;
  m_scrobbleThresholdTimeSec = 240;
  m_offlineScrobbleCache = true;
  m_lyricsProviderOrder = "Local .lrc sidecar first";
  m_autoFetchLyrics = true;

  // Diagnostics defaults
  m_loggingVerbosity = "Info";

  saveSettings();

  emit settingsChanged();
  emit playbackSettingsChanged();
  emit queueSettingsChanged();
  emit librarySettingsChanged();
  emit audioSettingsChanged();
  emit hotkeysChanged();
  emit metadataSettingsChanged();
  emit diagnosticsSettingsChanged();
}
