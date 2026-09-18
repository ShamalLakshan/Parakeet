#pragma once

#include <QAudioDevice>
#include <QMediaDevices>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <atomic>
#include <memory>
#include <thread>
#include <vector>

#include "core/services/LibraryService.hpp"
#include "core/services/PlayerService.hpp"
#include "core/services/QueueService.hpp"
#include "models/AlbumListModel.hpp"
#include "models/TrackListModel.hpp"
#include "theming/ThemeLoader.hpp"

/**
 * @brief Bridge exposing player services, library data, and theme tokens to
 * QML.
 */
class QtBridge : public QObject {
  Q_OBJECT

  // Models
  Q_PROPERTY(AlbumListModel *albumModel READ albumModel CONSTANT)
  Q_PROPERTY(TrackListModel *trackModel READ trackModel CONSTANT)
  Q_PROPERTY(
      TrackListModel *albumDetailTrackModel READ albumDetailTrackModel CONSTANT)
  Q_PROPERTY(TrackListModel *queueTrackModel READ queueTrackModel CONSTANT)

  // Theming Engine
  Q_PROPERTY(adapters::ThemeLoader *theme READ theme CONSTANT)

  // Current Playing Track State
  Q_PROPERTY(
      QString currentTrackTitle READ currentTrackTitle NOTIFY playbackChanged)
  Q_PROPERTY(QString currentArtist READ currentArtist NOTIFY playbackChanged)
  Q_PROPERTY(QString currentAlbum READ currentAlbum NOTIFY playbackChanged)
  Q_PROPERTY(QString currentYear READ currentYear NOTIFY playbackChanged)
  Q_PROPERTY(QString currentGenre READ currentGenre NOTIFY playbackChanged)
  Q_PROPERTY(QString currentCodec READ currentCodec NOTIFY playbackChanged)
  Q_PROPERTY(
      QString currentAudioSpecs READ currentAudioSpecs NOTIFY playbackChanged)
  Q_PROPERTY(QString currentArtHash READ currentArtHash NOTIFY playbackChanged)
  Q_PROPERTY(QString currentArtUrl READ currentArtUrl NOTIFY playbackChanged)
  Q_PROPERTY(
      QString currentFilePath READ currentFilePath NOTIFY playbackChanged)
  Q_PROPERTY(
      QString currentFileSizeStr READ currentFileSizeStr NOTIFY playbackChanged)
  Q_PROPERTY(int currentBitrate READ currentBitrate NOTIFY playbackChanged)
  Q_PROPERTY(
      int currentSampleRate READ currentSampleRate NOTIFY playbackChanged)
  Q_PROPERTY(int currentBitDepth READ currentBitDepth NOTIFY playbackChanged)
  Q_PROPERTY(int currentChannels READ currentChannels NOTIFY playbackChanged)
  Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackChanged)
  Q_PROPERTY(qint64 positionMs READ positionMs NOTIFY positionChanged)
  Q_PROPERTY(qint64 durationMs READ durationMs NOTIFY playbackChanged)
  Q_PROPERTY(QString positionStr READ positionStr NOTIFY positionChanged)
  Q_PROPERTY(QString durationStr READ durationStr NOTIFY playbackChanged)
  Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(bool isMuted READ isMuted NOTIFY volumeChanged)

  // Queue & Playback Modes
  Q_PROPERTY(int repeatMode READ repeatMode WRITE setRepeatMode NOTIFY
                 playbackModeChanged)
  Q_PROPERTY(int shuffleMode READ shuffleMode WRITE setShuffleMode NOTIFY
                 playbackModeChanged)
  Q_PROPERTY(
      int queueRemainingCount READ queueRemainingCount NOTIFY queueChanged)
  Q_PROPERTY(QString queueRemainingDurationStr READ queueRemainingDurationStr
                 NOTIFY queueChanged)
  Q_PROPERTY(int upNextCount READ upNextCount NOTIFY queueChanged)

  // Library Statistics
  Q_PROPERTY(int totalAlbums READ totalAlbums NOTIFY libraryStatsChanged)
  Q_PROPERTY(int totalTracks READ totalTracks NOTIFY libraryStatsChanged)
  Q_PROPERTY(
      QString totalDurationStr READ totalDurationStr NOTIFY libraryStatsChanged)
  Q_PROPERTY(QString totalLibrarySizeStr READ totalLibrarySizeStr NOTIFY
                 libraryStatsChanged)
  Q_PROPERTY(QStringList genresList READ genresList NOTIFY libraryStatsChanged)
  Q_PROPERTY(
      QStringList artistsList READ artistsList NOTIFY libraryStatsChanged)

  // Scanning State
  Q_PROPERTY(bool isScanning READ isScanning NOTIFY scanningChanged)
  Q_PROPERTY(QString scanStatusText READ scanStatusText NOTIFY scanningChanged)
  Q_PROPERTY(int scanScanned READ scanScanned NOTIFY scanningChanged)
  Q_PROPERTY(int scanTotal READ scanTotal NOTIFY scanningChanged)

  // Selected Album Details
  Q_PROPERTY(QString selectedAlbumTitle READ selectedAlbumTitle NOTIFY
                 selectedAlbumChanged)
  Q_PROPERTY(QString selectedAlbumArtist READ selectedAlbumArtist NOTIFY
                 selectedAlbumChanged)
  Q_PROPERTY(QString selectedAlbumYear READ selectedAlbumYear NOTIFY
                 selectedAlbumChanged)
  Q_PROPERTY(QString selectedAlbumGenre READ selectedAlbumGenre NOTIFY
                 selectedAlbumChanged)
  Q_PROPERTY(QString selectedAlbumQuality READ selectedAlbumQuality NOTIFY
                 selectedAlbumChanged)
  Q_PROPERTY(QString selectedAlbumDuration READ selectedAlbumDuration NOTIFY
                 selectedAlbumChanged)
  Q_PROPERTY(int selectedAlbumTrackCount READ selectedAlbumTrackCount NOTIFY
                 selectedAlbumChanged)
  Q_PROPERTY(QString selectedAlbumArtHash READ selectedAlbumArtHash NOTIFY
                 selectedAlbumChanged)

  // Settings (Playback & Library)
  Q_PROPERTY(
      QStringList monitoredFolders READ monitoredFolders NOTIFY settingsChanged)
  Q_PROPERTY(QString doubleClickAction READ doubleClickAction WRITE
                 setDoubleClickAction NOTIFY settingsChanged)
  Q_PROPERTY(QString queueAutoFillMode READ queueAutoFillMode WRITE
                 setQueueAutoFillMode NOTIFY settingsChanged)
  Q_PROPERTY(bool autoScanOnStartup READ autoScanOnStartup WRITE
                 setAutoScanOnStartup NOTIFY settingsChanged)

  // Settings (General)
  Q_PROPERTY(
      QString language READ language WRITE setLanguage NOTIFY settingsChanged)
  Q_PROPERTY(QString startupAction READ startupAction WRITE setStartupAction
                 NOTIFY settingsChanged)
  Q_PROPERTY(QString closeAction READ closeAction WRITE setCloseAction NOTIFY
                 settingsChanged)
  Q_PROPERTY(QString minimizeAction READ minimizeAction WRITE setMinimizeAction
                 NOTIFY settingsChanged)
  Q_PROPERTY(bool singleInstance READ singleInstance WRITE setSingleInstance
                 NOTIFY settingsChanged)
  Q_PROPERTY(QString updateCheckInterval READ updateCheckInterval WRITE
                 setUpdateCheckInterval NOTIFY settingsChanged)
  Q_PROPERTY(bool showNotifications READ showNotifications WRITE
                 setShowNotifications NOTIFY settingsChanged)
  Q_PROPERTY(int notificationDurationSec READ notificationDurationSec WRITE
                 setNotificationDurationSec NOTIFY settingsChanged)
  Q_PROPERTY(bool suppressNotificationsWhenFocused READ
                 suppressNotificationsWhenFocused WRITE
                     setSuppressNotificationsWhenFocused NOTIFY settingsChanged)

  // Settings (Appearance)
  Q_PROPERTY(QString fontFamily READ fontFamily WRITE setFontFamily NOTIFY
                 settingsChanged)
  Q_PROPERTY(int baseFontSize READ baseFontSize WRITE setBaseFontSize NOTIFY
                 settingsChanged)
  Q_PROPERTY(bool waveformSeekbar READ waveformSeekbar WRITE setWaveformSeekbar
                 NOTIFY settingsChanged)
  Q_PROPERTY(int tableRowHeight READ tableRowHeight WRITE setTableRowHeight
                 NOTIFY settingsChanged)
  Q_PROPERTY(bool tableAlternatingRows READ tableAlternatingRows WRITE
                 setTableAlternatingRows NOTIFY settingsChanged)
  Q_PROPERTY(QString artThumbnailQuality READ artThumbnailQuality WRITE
                 setArtThumbnailQuality NOTIFY settingsChanged)
  Q_PROPERTY(int artCacheLimitMb READ artCacheLimitMb WRITE setArtCacheLimitMb
                 NOTIFY settingsChanged)
  Q_PROPERTY(bool showStatusBar READ showStatusBar WRITE setShowStatusBar NOTIFY
                 settingsChanged)

  // Settings (Audio Output & Hardware Pipeline)
  Q_PROPERTY(QString audioBackend READ audioBackend WRITE setAudioBackend NOTIFY
                 audioSettingsChanged)
  Q_PROPERTY(QStringList availableAudioDevices READ availableAudioDevices NOTIFY
                 audioDevicesChanged)
  Q_PROPERTY(QString currentAudioDevice READ currentAudioDevice WRITE
                 setCurrentAudioDevice NOTIFY audioSettingsChanged)
  Q_PROPERTY(bool bitPerfectExclusive READ bitPerfectExclusive WRITE
                 setBitPerfectExclusive NOTIFY audioSettingsChanged)
  Q_PROPERTY(int bufferLatencyMs READ bufferLatencyMs WRITE setBufferLatencyMs
                 NOTIFY audioSettingsChanged)
  Q_PROPERTY(QString resamplerQuality READ resamplerQuality WRITE
                 setResamplerQuality NOTIFY audioSettingsChanged)
  Q_PROPERTY(QString ditherMode READ ditherMode WRITE setDitherMode NOTIFY
                 audioSettingsChanged)
  Q_PROPERTY(QString channelProcessing READ channelProcessing WRITE
                 setChannelProcessing NOTIFY audioSettingsChanged)

public:
  explicit QtBridge(core::PlayerService &player, core::LibraryService &library,
                    adapters::ThemeLoader *themeLoader = nullptr,
                    QObject *parent = nullptr);
  ~QtBridge() override = default;

  [[nodiscard]] AlbumListModel *albumModel() const { return m_albumModel; }
  [[nodiscard]] TrackListModel *trackModel() const { return m_trackModel; }
  [[nodiscard]] TrackListModel *albumDetailTrackModel() const {
    return m_albumDetailTrackModel;
  }
  [[nodiscard]] TrackListModel *queueTrackModel() const {
    return m_queueTrackModel;
  }
  [[nodiscard]] adapters::ThemeLoader *theme() const { return m_themeLoader; }

  [[nodiscard]] QString currentTrackTitle() const {
    return m_currentTrackTitle;
  }
  [[nodiscard]] QString currentArtist() const { return m_currentArtist; }
  [[nodiscard]] QString currentAlbum() const { return m_currentAlbum; }
  [[nodiscard]] QString currentYear() const { return m_currentYear; }
  [[nodiscard]] QString currentGenre() const { return m_currentGenre; }
  [[nodiscard]] QString currentCodec() const { return m_currentCodec; }
  [[nodiscard]] QString currentAudioSpecs() const {
    return m_currentAudioSpecs;
  }
  [[nodiscard]] QString currentArtHash() const { return m_currentArtHash; }
  [[nodiscard]] QString currentArtUrl() const;
  [[nodiscard]] QString currentFilePath() const { return m_currentFilePath; }
  [[nodiscard]] QString currentFileSizeStr() const {
    return m_currentFileSizeStr;
  }
  [[nodiscard]] int currentBitrate() const { return m_currentBitrate; }
  [[nodiscard]] int currentSampleRate() const { return m_currentSampleRate; }
  [[nodiscard]] int currentBitDepth() const { return m_currentBitDepth; }
  [[nodiscard]] int currentChannels() const { return m_currentChannels; }
  [[nodiscard]] bool isPlaying() const { return m_isPlaying; }
  [[nodiscard]] qint64 positionMs() const { return m_positionMs; }
  [[nodiscard]] qint64 durationMs() const { return m_durationMs; }
  [[nodiscard]] QString positionStr() const { return m_positionStr; }
  [[nodiscard]] QString durationStr() const { return m_durationStr; }
  [[nodiscard]] float volume() const { return m_volume; }
  [[nodiscard]] bool isMuted() const { return m_isMuted; }

  [[nodiscard]] int repeatMode() const;
  [[nodiscard]] int shuffleMode() const;
  [[nodiscard]] int queueRemainingCount() const;
  [[nodiscard]] QString queueRemainingDurationStr() const;
  [[nodiscard]] int upNextCount() const;

  [[nodiscard]] int totalAlbums() const;
  [[nodiscard]] int totalTracks() const;
  [[nodiscard]] QString totalDurationStr() const;
  [[nodiscard]] QString totalLibrarySizeStr() const;
  [[nodiscard]] QStringList genresList() const { return m_genresList; }
  [[nodiscard]] QStringList artistsList() const { return m_artistsList; }

  [[nodiscard]] bool isScanning() const { return m_isScanning; }
  [[nodiscard]] QString scanStatusText() const { return m_scanStatusText; }
  [[nodiscard]] int scanScanned() const { return m_scanScanned; }
  [[nodiscard]] int scanTotal() const { return m_scanTotal; }

  [[nodiscard]] QString selectedAlbumTitle() const {
    return m_selectedAlbumTitle;
  }
  [[nodiscard]] QString selectedAlbumArtist() const {
    return m_selectedAlbumArtist;
  }
  [[nodiscard]] QString selectedAlbumYear() const {
    return m_selectedAlbumYear;
  }
  [[nodiscard]] QString selectedAlbumGenre() const {
    return m_selectedAlbumGenre;
  }
  [[nodiscard]] QString selectedAlbumQuality() const {
    return m_selectedAlbumQuality;
  }
  [[nodiscard]] QString selectedAlbumDuration() const {
    return m_selectedAlbumDuration;
  }
  [[nodiscard]] int selectedAlbumTrackCount() const {
    return m_selectedAlbumTrackCount;
  }
  [[nodiscard]] QString selectedAlbumArtHash() const {
    return m_selectedAlbumArtHash;
  }

  [[nodiscard]] QStringList monitoredFolders() const {
    return m_monitoredFolders;
  }
  [[nodiscard]] QString doubleClickAction() const {
    return m_doubleClickAction;
  }
  [[nodiscard]] QString queueAutoFillMode() const {
    return m_queueAutoFillMode;
  }
  [[nodiscard]] bool autoScanOnStartup() const { return m_autoScanOnStartup; }

  // General Settings Getters
  [[nodiscard]] QString language() const { return m_language; }
  [[nodiscard]] QString startupAction() const { return m_startupAction; }
  [[nodiscard]] QString closeAction() const { return m_closeAction; }
  [[nodiscard]] QString minimizeAction() const { return m_minimizeAction; }
  [[nodiscard]] bool singleInstance() const { return m_singleInstance; }
  [[nodiscard]] QString updateCheckInterval() const {
    return m_updateCheckInterval;
  }
  [[nodiscard]] bool showNotifications() const { return m_showNotifications; }
  [[nodiscard]] int notificationDurationSec() const {
    return m_notificationDurationSec;
  }
  [[nodiscard]] bool suppressNotificationsWhenFocused() const {
    return m_suppressNotificationsWhenFocused;
  }

  // Appearance Settings Getters
  [[nodiscard]] QString fontFamily() const { return m_fontFamily; }
  [[nodiscard]] int baseFontSize() const { return m_baseFontSize; }
  [[nodiscard]] bool waveformSeekbar() const { return m_waveformSeekbar; }
  [[nodiscard]] int tableRowHeight() const { return m_tableRowHeight; }
  [[nodiscard]] bool tableAlternatingRows() const {
    return m_tableAlternatingRows;
  }
  [[nodiscard]] QString artThumbnailQuality() const {
    return m_artThumbnailQuality;
  }
  [[nodiscard]] int artCacheLimitMb() const { return m_artCacheLimitMb; }
  [[nodiscard]] bool showStatusBar() const { return m_showStatusBar; }

  // Audio Output Settings Getters
  [[nodiscard]] QString audioBackend() const { return m_audioBackend; }
  [[nodiscard]] QStringList availableAudioDevices() const {
    return m_availableAudioDevices;
  }
  [[nodiscard]] QString currentAudioDevice() const {
    return m_currentAudioDevice;
  }
  [[nodiscard]] bool bitPerfectExclusive() const {
    return m_bitPerfectExclusive;
  }
  [[nodiscard]] int bufferLatencyMs() const { return m_bufferLatencyMs; }
  [[nodiscard]] QString resamplerQuality() const { return m_resamplerQuality; }
  [[nodiscard]] QString ditherMode() const { return m_ditherMode; }
  [[nodiscard]] QString channelProcessing() const {
    return m_channelProcessing;
  }

  // QML-invokable actions
  Q_INVOKABLE void scanDirectory(const QString &folderPath);
  Q_INVOKABLE void purgeMissingTracks();
  Q_INVOKABLE void clearLibrary();
  Q_INVOKABLE void search(const QString &query);
  Q_INVOKABLE void filterByLetter(const QString &letter);
  Q_INVOKABLE void filterByGenre(const QString &genre);
  Q_INVOKABLE void filterByArtist(const QString &artist);
  Q_INVOKABLE void resetFilters();
  Q_INVOKABLE void openAlbumDetails(const QString &albumTitle,
                                    const QString &albumArtist);
  Q_INVOKABLE void playAlbum(const QString &albumTitle,
                             const QString &albumArtist);
  Q_INVOKABLE void playTrack(const QString &trackId);
  Q_INVOKABLE void playTrackAtIndex(int index);
  Q_INVOKABLE void playTrackFromDetail(int index);
  Q_INVOKABLE void playQueueTrack(int index);
  Q_INVOKABLE void queueTrack(const QString &trackId);

  // Queue operations
  Q_INVOKABLE void playNow(const QString &trackId);
  Q_INVOKABLE void playNext(const QString &trackId);
  Q_INVOKABLE void queueLast(const QString &trackId);
  Q_INVOKABLE void playAlbumNow(const QString &albumTitle,
                                const QString &albumArtist);
  Q_INVOKABLE void playAlbumNext(const QString &albumTitle,
                                 const QString &albumArtist);
  Q_INVOKABLE void queueAlbumLast(const QString &albumTitle,
                                  const QString &albumArtist);
  Q_INVOKABLE void removeFromQueue(int index);
  Q_INVOKABLE void moveQueueItem(int fromIndex, int toIndex);
  Q_INVOKABLE void clearQueue();
  Q_INVOKABLE void shuffleRemainingQueue();

  // Mode toggles
  Q_INVOKABLE void setRepeatMode(int mode);
  Q_INVOKABLE void cycleRepeatMode();
  Q_INVOKABLE void setShuffleMode(int mode);
  Q_INVOKABLE void cycleShuffleMode();

  // Transport controls
  Q_INVOKABLE void togglePlayPause();
  Q_INVOKABLE void stop();
  Q_INVOKABLE void nextTrack();
  Q_INVOKABLE void previousTrack();
  Q_INVOKABLE void seek(qint64 posMs);
  Q_INVOKABLE void setVolume(float volume);
  Q_INVOKABLE void toggleMute();
  Q_INVOKABLE void playAll();
  Q_INVOKABLE void shuffleAll();

  // Utilities
  Q_INVOKABLE void showInFileManager(const QString &filePath);
  Q_INVOKABLE void copyToClipboard(const QString &text);

  // Settings
  Q_INVOKABLE void addMonitoredFolder(const QString &folderPath);
  Q_INVOKABLE void removeMonitoredFolder(int index);
  Q_INVOKABLE void rescanAllMonitoredFolders();
  Q_INVOKABLE void setDoubleClickAction(const QString &action);
  Q_INVOKABLE void setQueueAutoFillMode(const QString &mode);
  Q_INVOKABLE void setAutoScanOnStartup(bool enable);
  Q_INVOKABLE void exportDatabaseBackup(const QString &targetFilePath);

  // General Settings
  Q_INVOKABLE void setLanguage(const QString &lang);
  Q_INVOKABLE void setStartupAction(const QString &action);
  Q_INVOKABLE void setCloseAction(const QString &action);
  Q_INVOKABLE void setMinimizeAction(const QString &action);
  Q_INVOKABLE void setSingleInstance(bool enable);
  Q_INVOKABLE void setUpdateCheckInterval(const QString &interval);
  Q_INVOKABLE void setShowNotifications(bool enable);
  Q_INVOKABLE void setNotificationDurationSec(int sec);
  Q_INVOKABLE void setSuppressNotificationsWhenFocused(bool enable);

  // Appearance Settings
  Q_INVOKABLE void setFontFamily(const QString &font);
  Q_INVOKABLE void setBaseFontSize(int size);
  Q_INVOKABLE void setWaveformSeekbar(bool enable);
  Q_INVOKABLE void setTableRowHeight(int height);
  Q_INVOKABLE void setTableAlternatingRows(bool enable);
  Q_INVOKABLE void setArtThumbnailQuality(const QString &quality);
  Q_INVOKABLE void setArtCacheLimitMb(int limitMb);
  Q_INVOKABLE void setShowStatusBar(bool enable);

  // Audio Output Settings
  Q_INVOKABLE void setAudioBackend(const QString &backend);
  Q_INVOKABLE void setCurrentAudioDevice(const QString &device);
  Q_INVOKABLE void setBitPerfectExclusive(bool exclusive);
  Q_INVOKABLE void setBufferLatencyMs(int ms);
  Q_INVOKABLE void setResamplerQuality(const QString &quality);
  Q_INVOKABLE void setDitherMode(const QString &mode);
  Q_INVOKABLE void setChannelProcessing(const QString &mode);

  // Maintenance Utilities
  Q_INVOKABLE void clearArtCache();
  Q_INVOKABLE void checkForUpdates();
  Q_INVOKABLE void refreshAudioDevices();

signals:
  void playbackChanged();
  void positionChanged();
  void volumeChanged();
  void libraryStatsChanged();
  void scanningChanged();
  void selectedAlbumChanged();
  void scanFinished(int count);
  void playbackModeChanged();
  void queueChanged();
  void settingsChanged();
  void audioSettingsChanged();
  void audioDevicesChanged();

private:
  void setupPositionTimer();
  void updatePlaybackState(const core::Track &track);
  void refreshLibraryStats();
  void syncQueueModel();
  void loadSettings();
  void saveSettings();
  static QString formatTime(qint64 ms);
  static QString formatBytes(uint64_t bytes);

  core::PlayerService &m_player;
  core::LibraryService &m_library;
  adapters::ThemeLoader *m_themeLoader{nullptr};

  AlbumListModel *m_albumModel{nullptr};
  TrackListModel *m_trackModel{nullptr};
  TrackListModel *m_albumDetailTrackModel{nullptr};
  TrackListModel *m_queueTrackModel{nullptr};

  // Playback state (idle by default)
  QString m_currentTrackTitle{"No Track Selected"};
  QString m_currentArtist{""};
  QString m_currentAlbum{""};
  QString m_currentYear{""};
  QString m_currentGenre{""};
  QString m_currentCodec{""};
  QString m_currentAudioSpecs{"Engine Idle • Ready"};
  QString m_currentArtHash{""};
  QString m_currentFilePath{""};
  QString m_currentFileSizeStr{""};
  int m_currentBitrate{0};
  int m_currentSampleRate{0};
  int m_currentBitDepth{0};
  int m_currentChannels{0};
  bool m_isPlaying{false};
  qint64 m_positionMs{0};
  qint64 m_durationMs{0};
  QString m_positionStr{"00:00"};
  QString m_durationStr{"00:00"};
  float m_volume{0.8f};
  float m_prevVolume{0.8f};
  bool m_isMuted{false};

  // Scanning state
  std::atomic<bool> m_isScanning{false};
  QString m_scanStatusText{"Ready"};
  int m_scanScanned{0};
  int m_scanTotal{0};

  // Filter lists
  QStringList m_genresList;
  QStringList m_artistsList;

  // Selected album info
  QString m_selectedAlbumTitle;
  QString m_selectedAlbumArtist;
  QString m_selectedAlbumYear;
  QString m_selectedAlbumGenre;
  QString m_selectedAlbumQuality;
  QString m_selectedAlbumDuration;
  int m_selectedAlbumTrackCount{0};
  QString m_selectedAlbumArtHash;

  // Settings
  QStringList m_monitoredFolders;
  QString m_doubleClickAction{"Play Now"};
  QString m_queueAutoFillMode{"Loop Album"};
  bool m_autoScanOnStartup{false};

  // General Settings
  QString m_language{"System Default"};
  QString m_startupAction{"Restore Session"};
  QString m_closeAction{"Exit Application"};
  QString m_minimizeAction{"Minimize to Taskbar"};
  bool m_singleInstance{true};
  QString m_updateCheckInterval{"Weekly"};
  bool m_showNotifications{true};
  int m_notificationDurationSec{4};
  bool m_suppressNotificationsWhenFocused{true};

  // Appearance Settings
  QString m_fontFamily{"Inter, sans-serif"};
  int m_baseFontSize{11};
  bool m_waveformSeekbar{true};
  int m_tableRowHeight{32};
  bool m_tableAlternatingRows{false};
  QString m_artThumbnailQuality{"Smooth (High Quality)"};
  int m_artCacheLimitMb{1024};
  bool m_showStatusBar{true};

  // Audio Output & Pipeline Settings
  QString m_audioBackend{"Linux PipeWire Lock-Free Client"};
  QStringList m_availableAudioDevices{"System Default Output"};
  QString m_currentAudioDevice{"System Default Output"};
  bool m_bitPerfectExclusive{true};
  int m_bufferLatencyMs{50};
  QString m_resamplerQuality{"SoX Resampler High Quality"};
  QString m_ditherMode{"Flat TPDF (Triangular)"};
  QString m_channelProcessing{"Stereo Passthrough"};

  QMediaDevices *m_mediaDevices{nullptr};
  QTimer *m_positionTimer{nullptr};
};
