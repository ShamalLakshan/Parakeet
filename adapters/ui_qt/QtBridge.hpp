#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <vector>
#include <memory>
#include <thread>
#include <atomic>

#include "core/services/PlayerService.hpp"
#include "core/services/LibraryService.hpp"
#include "models/AlbumListModel.hpp"
#include "models/TrackListModel.hpp"

/**
 * @brief Audiophile UI Bridge exposing domain services, state, and models to Qt Quick.
 */
class QtBridge : public QObject {
    Q_OBJECT

    // Models
    Q_PROPERTY(AlbumListModel* albumModel READ albumModel CONSTANT)
    Q_PROPERTY(TrackListModel* trackModel READ trackModel CONSTANT)
    Q_PROPERTY(TrackListModel* albumDetailTrackModel READ albumDetailTrackModel CONSTANT)
    Q_PROPERTY(TrackListModel* queueTrackModel READ queueTrackModel CONSTANT)

    // Current Playing Track State
    Q_PROPERTY(QString currentTrackTitle READ currentTrackTitle NOTIFY playbackChanged)
    Q_PROPERTY(QString currentArtist READ currentArtist NOTIFY playbackChanged)
    Q_PROPERTY(QString currentAlbum READ currentAlbum NOTIFY playbackChanged)
    Q_PROPERTY(QString currentYear READ currentYear NOTIFY playbackChanged)
    Q_PROPERTY(QString currentGenre READ currentGenre NOTIFY playbackChanged)
    Q_PROPERTY(QString currentCodec READ currentCodec NOTIFY playbackChanged)
    Q_PROPERTY(QString currentAudioSpecs READ currentAudioSpecs NOTIFY playbackChanged)
    Q_PROPERTY(QString currentArtHash READ currentArtHash NOTIFY playbackChanged)
    Q_PROPERTY(QString currentArtUrl READ currentArtUrl NOTIFY playbackChanged)
    Q_PROPERTY(QString currentFilePath READ currentFilePath NOTIFY playbackChanged)
    Q_PROPERTY(QString currentFileSizeStr READ currentFileSizeStr NOTIFY playbackChanged)
    Q_PROPERTY(int currentBitrate READ currentBitrate NOTIFY playbackChanged)
    Q_PROPERTY(int currentSampleRate READ currentSampleRate NOTIFY playbackChanged)
    Q_PROPERTY(int currentBitDepth READ currentBitDepth NOTIFY playbackChanged)
    Q_PROPERTY(int currentChannels READ currentChannels NOTIFY playbackChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackChanged)
    Q_PROPERTY(qint64 positionMs READ positionMs NOTIFY positionChanged)
    Q_PROPERTY(qint64 durationMs READ durationMs NOTIFY playbackChanged)
    Q_PROPERTY(QString positionStr READ positionStr NOTIFY positionChanged)
    Q_PROPERTY(QString durationStr READ durationStr NOTIFY playbackChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool isMuted READ isMuted NOTIFY volumeChanged)

    // Library Statistics
    Q_PROPERTY(int totalAlbums READ totalAlbums NOTIFY libraryStatsChanged)
    Q_PROPERTY(int totalTracks READ totalTracks NOTIFY libraryStatsChanged)
    Q_PROPERTY(QString totalDurationStr READ totalDurationStr NOTIFY libraryStatsChanged)
    Q_PROPERTY(QString totalLibrarySizeStr READ totalLibrarySizeStr NOTIFY libraryStatsChanged)
    Q_PROPERTY(QStringList genresList READ genresList NOTIFY libraryStatsChanged)
    Q_PROPERTY(QStringList artistsList READ artistsList NOTIFY libraryStatsChanged)

    // Scanning State
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY scanningChanged)
    Q_PROPERTY(QString scanStatusText READ scanStatusText NOTIFY scanningChanged)
    Q_PROPERTY(int scanScanned READ scanScanned NOTIFY scanningChanged)
    Q_PROPERTY(int scanTotal READ scanTotal NOTIFY scanningChanged)

    // Selected Album Details
    Q_PROPERTY(QString selectedAlbumTitle READ selectedAlbumTitle NOTIFY selectedAlbumChanged)
    Q_PROPERTY(QString selectedAlbumArtist READ selectedAlbumArtist NOTIFY selectedAlbumChanged)
    Q_PROPERTY(QString selectedAlbumYear READ selectedAlbumYear NOTIFY selectedAlbumChanged)
    Q_PROPERTY(QString selectedAlbumGenre READ selectedAlbumGenre NOTIFY selectedAlbumChanged)
    Q_PROPERTY(QString selectedAlbumQuality READ selectedAlbumQuality NOTIFY selectedAlbumChanged)
    Q_PROPERTY(QString selectedAlbumDuration READ selectedAlbumDuration NOTIFY selectedAlbumChanged)
    Q_PROPERTY(int selectedAlbumTrackCount READ selectedAlbumTrackCount NOTIFY selectedAlbumChanged)
    Q_PROPERTY(QString selectedAlbumArtHash READ selectedAlbumArtHash NOTIFY selectedAlbumChanged)

public:
    explicit QtBridge(core::PlayerService& player, 
                      core::LibraryService& library, 
                      QObject* parent = nullptr);
    ~QtBridge() override = default;

    [[nodiscard]] AlbumListModel* albumModel() const { return m_albumModel; }
    [[nodiscard]] TrackListModel* trackModel() const { return m_trackModel; }
    [[nodiscard]] TrackListModel* albumDetailTrackModel() const { return m_albumDetailTrackModel; }
    [[nodiscard]] TrackListModel* queueTrackModel() const { return m_queueTrackModel; }

    [[nodiscard]] QString currentTrackTitle() const { return m_currentTrackTitle; }
    [[nodiscard]] QString currentArtist() const { return m_currentArtist; }
    [[nodiscard]] QString currentAlbum() const { return m_currentAlbum; }
    [[nodiscard]] QString currentYear() const { return m_currentYear; }
    [[nodiscard]] QString currentGenre() const { return m_currentGenre; }
    [[nodiscard]] QString currentCodec() const { return m_currentCodec; }
    [[nodiscard]] QString currentAudioSpecs() const { return m_currentAudioSpecs; }
    [[nodiscard]] QString currentArtHash() const { return m_currentArtHash; }
    [[nodiscard]] QString currentArtUrl() const;
    [[nodiscard]] QString currentFilePath() const { return m_currentFilePath; }
    [[nodiscard]] QString currentFileSizeStr() const { return m_currentFileSizeStr; }
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

    [[nodiscard]] QString selectedAlbumTitle() const { return m_selectedAlbumTitle; }
    [[nodiscard]] QString selectedAlbumArtist() const { return m_selectedAlbumArtist; }
    [[nodiscard]] QString selectedAlbumYear() const { return m_selectedAlbumYear; }
    [[nodiscard]] QString selectedAlbumGenre() const { return m_selectedAlbumGenre; }
    [[nodiscard]] QString selectedAlbumQuality() const { return m_selectedAlbumQuality; }
    [[nodiscard]] QString selectedAlbumDuration() const { return m_selectedAlbumDuration; }
    [[nodiscard]] int selectedAlbumTrackCount() const { return m_selectedAlbumTrackCount; }
    [[nodiscard]] QString selectedAlbumArtHash() const { return m_selectedAlbumArtHash; }

    // QML-invokable actions
    Q_INVOKABLE void scanDirectory(const QString& folderPath);
    Q_INVOKABLE void purgeMissingTracks();
    Q_INVOKABLE void clearLibrary();
    Q_INVOKABLE void search(const QString& query);
    Q_INVOKABLE void filterByLetter(const QString& letter);
    Q_INVOKABLE void filterByGenre(const QString& genre);
    Q_INVOKABLE void filterByArtist(const QString& artist);
    Q_INVOKABLE void resetFilters();
    Q_INVOKABLE void openAlbumDetails(const QString& albumTitle, const QString& albumArtist);
    Q_INVOKABLE void playAlbum(const QString& albumTitle, const QString& albumArtist);
    Q_INVOKABLE void playTrack(const QString& trackId);
    Q_INVOKABLE void playTrackAtIndex(int index);
    Q_INVOKABLE void playTrackFromDetail(int index);
    Q_INVOKABLE void playQueueTrack(int index);
    Q_INVOKABLE void queueTrack(const QString& trackId);
    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void nextTrack();
    Q_INVOKABLE void previousTrack();
    Q_INVOKABLE void seek(qint64 posMs);
    Q_INVOKABLE void setVolume(float volume);
    Q_INVOKABLE void toggleMute();
    Q_INVOKABLE void playAll();
    Q_INVOKABLE void shuffleAll();

signals:
    void playbackChanged();
    void positionChanged();
    void volumeChanged();
    void libraryStatsChanged();
    void scanningChanged();
    void selectedAlbumChanged();
    void scanFinished(int count);

private:
    void setupPositionTimer();
    void updatePlaybackState(const core::Track& track);
    void refreshLibraryStats();
    static QString formatTime(qint64 ms);
    static QString formatBytes(uint64_t bytes);

    core::PlayerService& m_player;
    core::LibraryService& m_library;

    AlbumListModel* m_albumModel{nullptr};
    TrackListModel* m_trackModel{nullptr};
    TrackListModel* m_albumDetailTrackModel{nullptr};
    TrackListModel* m_queueTrackModel{nullptr};

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

    QTimer* m_positionTimer{nullptr};
    std::vector<core::Track> m_currentPlaylist;
    int m_currentPlaylistIndex{0};
};
