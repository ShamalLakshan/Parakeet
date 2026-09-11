#include "QtBridge.hpp"
#include <QUrl>
#include <algorithm>
#include <random>
#include <set>
#include <iostream>

QtBridge::QtBridge(core::PlayerService& player, 
                   core::LibraryService& library, 
                   QObject* parent)
    : QObject(parent), m_player(player), m_library(library) {
    
    // Purge any dead/fake paths on startup
    m_library.purgeNonExistentTracks();

    m_albumModel = new AlbumListModel(&m_library.getDatabasePort(), this);
    m_trackModel = new TrackListModel(&m_library.getDatabasePort(), this);
    m_albumDetailTrackModel = new TrackListModel(&m_library.getDatabasePort(), this);
    m_queueTrackModel = new TrackListModel(&m_library.getDatabasePort(), this);

    refreshLibraryStats();
    setupPositionTimer();
}

void QtBridge::setupPositionTimer() {
    m_positionTimer = new QTimer(this);
    m_positionTimer->setInterval(250); // 4Hz smooth position update
    connect(m_positionTimer, &QTimer::timeout, this, [this]() {
        if (m_isPlaying) {
            uint64_t realPos = m_player.getPositionMs();
            m_positionMs = static_cast<qint64>(realPos);
            m_positionStr = formatTime(m_positionMs);
            emit positionChanged();

            // Duration check
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
    std::snprintf(buf, sizeof(buf), "%02lld:%02lld", static_cast<long long>(min), static_cast<long long>(sec));
    return QString::fromUtf8(buf);
}

QString QtBridge::formatBytes(uint64_t bytes) {
    if (bytes == 0) return "0 MB";
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

int QtBridge::totalAlbums() const {
    return static_cast<int>(m_library.getDatabasePort().getAlbumCount());
}

int QtBridge::totalTracks() const {
    return static_cast<int>(m_library.getDatabasePort().getTrackCount());
}

QString QtBridge::totalDurationStr() const {
    auto all = m_library.getTracks();
    uint64_t totalMs = 0;
    for (const auto& t : all) totalMs += t.durationMs;
    uint64_t totalSec = totalMs / 1000;
    uint64_t hours = totalSec / 3600;
    uint64_t min = (totalSec % 3600) / 60;
    uint64_t sec = totalSec % 60;
    if (hours > 0) {
        return QString::asprintf("%lluh %02llum %02llus", (unsigned long long)hours, (unsigned long long)min, (unsigned long long)sec);
    }
    return QString::asprintf("%llum %02llus", (unsigned long long)min, (unsigned long long)sec);
}

QString QtBridge::totalLibrarySizeStr() const {
    auto all = m_library.getTracks();
    uint64_t totalBytes = 0;
    for (const auto& t : all) totalBytes += t.fileSizeBytes;
    return formatBytes(totalBytes);
}

void QtBridge::refreshLibraryStats() {
    auto all = m_library.getTracks();
    std::set<std::string> genres;
    std::set<std::string> artists;
    for (const auto& t : all) {
        if (!t.genre.empty()) genres.insert(t.genre);
        if (!t.artist.empty()) artists.insert(t.artist);
    }

    m_genresList.clear();
    for (const auto& g : genres) m_genresList.append(QString::fromStdString(g));

    m_artistsList.clear();
    for (const auto& a : artists) m_artistsList.append(QString::fromStdString(a));

    emit libraryStatsChanged();
}

void QtBridge::scanDirectory(const QString& folderPath) {
    if (m_isScanning) return;

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
        size_t count = m_library.scanDirectory(path, [this](size_t scanned, size_t total) {
            QMetaObject::invokeMethod(this, [this, scanned, total]() {
                m_scanScanned = static_cast<int>(scanned);
                m_scanTotal = static_cast<int>(total);
                m_scanStatusText = QString("Indexed %1 / %2 tracks...").arg(scanned).arg(total);
                emit scanningChanged();
            }, Qt::QueuedConnection);
        });

        QMetaObject::invokeMethod(this, [this, count]() {
            m_albumModel->reload();
            m_trackModel->loadAllTracks();
            refreshLibraryStats();
            m_isScanning = false;
            m_scanStatusText = QString("Scan complete: %1 tracks indexed").arg(count);
            emit scanningChanged();
            emit scanFinished(static_cast<int>(count));
        }, Qt::QueuedConnection);
    }).detach();
}

void QtBridge::purgeMissingTracks() {
    size_t count = m_library.purgeNonExistentTracks();
    m_albumModel->reload();
    m_trackModel->loadAllTracks();
    refreshLibraryStats();
    m_scanStatusText = QString("Purged %1 non-existent tracks").arg(count);
    emit scanningChanged();
}

void QtBridge::clearLibrary() {
    m_library.clearLibrary();
    m_currentPlaylist.clear();
    m_queueTrackModel->setTracks({});
    m_albumModel->reload();
    m_trackModel->loadAllTracks();
    refreshLibraryStats();
    m_scanStatusText = "Library cleared";
    emit scanningChanged();
}

void QtBridge::search(const QString& query) {
    m_albumModel->setFilter(query);
    m_trackModel->setFilter(query);
}

void QtBridge::filterByLetter(const QString& letter) {
    if (letter.isEmpty() || letter == "All") {
        m_albumModel->setFilter("");
        m_trackModel->setFilter("");
    } else {
        m_albumModel->setFilter(letter);
        m_trackModel->setFilter(letter);
    }
}

void QtBridge::filterByGenre(const QString& genre) {
    if (genre.isEmpty() || genre == "All") {
        m_trackModel->setFilter("");
    } else {
        m_trackModel->setFilter(genre);
    }
}

void QtBridge::filterByArtist(const QString& artist) {
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

void QtBridge::openAlbumDetails(const QString& albumTitle, const QString& albumArtist) {
    auto albumOpt = m_library.getDatabasePort().getAlbumById("alb_" + albumTitle.toStdString() + "_" + albumArtist.toStdString());
    if (albumOpt) {
        const auto& a = *albumOpt;
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

void QtBridge::playAlbum(const QString& albumTitle, const QString& albumArtist) {
    auto tracks = m_library.getTracksForAlbum(albumTitle.toStdString(), albumArtist.toStdString());
    if (!tracks.empty()) {
        m_currentPlaylist = tracks;
        m_currentPlaylistIndex = 0;
        m_queueTrackModel->setTracks(m_currentPlaylist);
        updatePlaybackState(m_currentPlaylist[0]);
    }
}

void QtBridge::playTrack(const QString& trackId) {
    auto trackOpt = m_library.getTrackById(trackId.toStdString());
    if (trackOpt) {
        m_currentPlaylist = { *trackOpt };
        m_currentPlaylistIndex = 0;
        m_queueTrackModel->setTracks(m_currentPlaylist);
        updatePlaybackState(*trackOpt);
    }
}

void QtBridge::playTrackAtIndex(int index) {
    auto trackMap = m_trackModel->getTrackAt(index);
    if (!trackMap.isEmpty()) {
        QString id = trackMap["id"].toString();
        // Load all current tracks into playlist starting at index
        m_currentPlaylist = m_library.getTracks();
        m_currentPlaylistIndex = std::clamp(index, 0, static_cast<int>(m_currentPlaylist.size()) - 1);
        m_queueTrackModel->setTracks(m_currentPlaylist);
        if (!m_currentPlaylist.empty()) {
            updatePlaybackState(m_currentPlaylist[static_cast<size_t>(m_currentPlaylistIndex)]);
        }
    }
}

void QtBridge::playTrackFromDetail(int index) {
    auto trackMap = m_albumDetailTrackModel->getTrackAt(index);
    if (!trackMap.isEmpty()) {
        QString id = trackMap["id"].toString();
        auto tracks = m_library.getTracksForAlbum(m_selectedAlbumTitle.toStdString(), m_selectedAlbumArtist.toStdString());
        if (!tracks.empty()) {
            m_currentPlaylist = tracks;
            m_currentPlaylistIndex = std::clamp(index, 0, static_cast<int>(m_currentPlaylist.size()) - 1);
            m_queueTrackModel->setTracks(m_currentPlaylist);
            updatePlaybackState(m_currentPlaylist[static_cast<size_t>(m_currentPlaylistIndex)]);
        }
    }
}

void QtBridge::playQueueTrack(int index) {
    if (index >= 0 && index < static_cast<int>(m_currentPlaylist.size())) {
        m_currentPlaylistIndex = index;
        updatePlaybackState(m_currentPlaylist[static_cast<size_t>(m_currentPlaylistIndex)]);
    }
}

void QtBridge::queueTrack(const QString& trackId) {
    auto trackOpt = m_library.getTrackById(trackId.toStdString());
    if (trackOpt) {
        m_currentPlaylist.push_back(*trackOpt);
        m_queueTrackModel->setTracks(m_currentPlaylist);
    }
}

void QtBridge::updatePlaybackState(const core::Track& track) {
    m_player.play(track);
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

    // Audio specs formatting
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
    if (track.channels == 1) spec += " • Mono";
    else if (track.channels == 2) spec += " • Stereo";
    else if (track.channels > 2) spec += QString(" • %1 Ch").arg(track.channels);

    m_currentAudioSpecs = spec;
    m_currentArtHash = QString::fromStdString(track.artHash);
    m_durationMs = static_cast<qint64>(track.durationMs);
    m_positionMs = 0;
    m_positionStr = "00:00";
    m_durationStr = QString::fromStdString(track.durationFormatted());

    m_positionTimer->start();
    emit playbackChanged();
    emit positionChanged();
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
    if (m_currentPlaylist.empty()) return;
    m_currentPlaylistIndex = (m_currentPlaylistIndex + 1) % static_cast<int>(m_currentPlaylist.size());
    updatePlaybackState(m_currentPlaylist[static_cast<size_t>(m_currentPlaylistIndex)]);
}

void QtBridge::previousTrack() {
    if (m_currentPlaylist.empty()) return;
    m_currentPlaylistIndex = (m_currentPlaylistIndex - 1 + static_cast<int>(m_currentPlaylist.size())) % static_cast<int>(m_currentPlaylist.size());
    updatePlaybackState(m_currentPlaylist[static_cast<size_t>(m_currentPlaylistIndex)]);
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

void QtBridge::playAll() {
    m_currentPlaylist = m_library.getTracks();
    if (!m_currentPlaylist.empty()) {
        m_currentPlaylistIndex = 0;
        m_queueTrackModel->setTracks(m_currentPlaylist);
        updatePlaybackState(m_currentPlaylist[0]);
    }
}

void QtBridge::shuffleAll() {
    m_currentPlaylist = m_library.getTracks();
    if (!m_currentPlaylist.empty()) {
        std::random_device rd;
        std::mt19937 g(rd());
        std::shuffle(m_currentPlaylist.begin(), m_currentPlaylist.end(), g);
        m_currentPlaylistIndex = 0;
        m_queueTrackModel->setTracks(m_currentPlaylist);
        updatePlaybackState(m_currentPlaylist[0]);
    }
}
