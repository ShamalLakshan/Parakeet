#include "TrackListModel.hpp"
#include "core/ports/IMusicDatabasePort.hpp"

TrackListModel::TrackListModel(core::IMusicDatabasePort* dbPort, QObject* parent)
    : QAbstractListModel(parent), m_dbPort(dbPort) {
    if (m_dbPort) {
        loadAllTracks();
    }
}

void TrackListModel::setDatabasePort(core::IMusicDatabasePort* dbPort) {
    m_dbPort = dbPort;
}

void TrackListModel::setTracks(const std::vector<core::Track>& tracks) {
    beginResetModel();
    m_allTracks = tracks;
    m_filteredTracks = tracks;
    m_filterText.clear();
    endResetModel();
    emit countChanged();
}

void TrackListModel::loadAllTracks() {
    beginResetModel();
    m_allTracks.clear();
    m_filteredTracks.clear();
    if (m_dbPort) {
        m_allTracks = m_dbPort->getAllTracks();
    }
    applyFilter();
    endResetModel();
    emit countChanged();
}

void TrackListModel::loadAlbumTracks(const QString& albumTitle, const QString& albumArtist) {
    beginResetModel();
    m_allTracks.clear();
    m_filteredTracks.clear();
    if (m_dbPort) {
        m_allTracks = m_dbPort->getTracksByAlbum(albumTitle.toStdString(), albumArtist.toStdString());
    }
    applyFilter();
    endResetModel();
    emit countChanged();
}

void TrackListModel::setFilter(const QString& filterText) {
    if (m_filterText == filterText) return;
    m_filterText = filterText;
    beginResetModel();
    applyFilter();
    endResetModel();
    emit countChanged();
}

void TrackListModel::applyFilter() {
    if (m_filterText.trimmed().isEmpty()) {
        m_filteredTracks = m_allTracks;
        return;
    }

    m_filteredTracks.clear();
    QString lower = m_filterText.toLower();
    for (const auto& t : m_allTracks) {
        QString title = QString::fromStdString(t.title).toLower();
        QString artist = QString::fromStdString(t.artist).toLower();
        QString album = QString::fromStdString(t.album).toLower();
        QString genre = QString::fromStdString(t.genre).toLower();
        if (title.contains(lower) || artist.contains(lower) || album.contains(lower) || genre.contains(lower)) {
            m_filteredTracks.push_back(t);
        }
    }
}

int TrackListModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return static_cast<int>(m_filteredTracks.size());
}

QVariant TrackListModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= static_cast<int>(m_filteredTracks.size())) {
        return QVariant();
    }

    const auto& track = m_filteredTracks[static_cast<size_t>(index.row())];

    switch (role) {
    case IdRole:
        return QString::fromStdString(track.id);
    case FilePathRole:
        return QString::fromStdString(track.filePath);
    case TitleRole:
        return QString::fromStdString(track.title);
    case ArtistRole:
        return QString::fromStdString(track.artist);
    case AlbumRole:
        return QString::fromStdString(track.album);
    case AlbumArtistRole:
        return QString::fromStdString(track.albumArtist);
    case GenreRole:
        return QString::fromStdString(track.genre);
    case YearRole:
        return track.year > 0 ? QVariant(track.year) : QVariant();
    case TrackNumberRole:
        return track.trackNumber;
    case DiscNumberRole:
        return track.discNumber;
    case DurationMsRole:
        return static_cast<qint64>(track.durationMs);
    case DurationFormattedRole:
        return QString::fromStdString(track.durationFormatted());
    case SampleRateRole:
        return track.sampleRate;
    case BitDepthRole:
        return track.bitDepth;
    case ChannelsRole:
        return track.channels;
    case BitrateRole:
        return track.bitrate;
    case CodecRole:
        return QString::fromStdString(track.codec);
    case ArtHashRole:
        return QString::fromStdString(track.artHash);
    case AudiophileBadgeRole:
        return QString::fromStdString(track.audiophileBadge());
    default:
        return QVariant();
    }
}

QVariantMap TrackListModel::getTrackAt(int index) const {
    QVariantMap map;
    if (index < 0 || index >= static_cast<int>(m_filteredTracks.size())) {
        return map;
    }
    const auto& t = m_filteredTracks[static_cast<size_t>(index)];
    map["id"] = QString::fromStdString(t.id);
    map["filePath"] = QString::fromStdString(t.filePath);
    map["title"] = QString::fromStdString(t.title);
    map["artist"] = QString::fromStdString(t.artist);
    map["album"] = QString::fromStdString(t.album);
    map["year"] = t.year;
    map["genre"] = QString::fromStdString(t.genre);
    map["trackNumber"] = t.trackNumber;
    map["durationFormatted"] = QString::fromStdString(t.durationFormatted());
    map["durationMs"] = static_cast<qint64>(t.durationMs);
    map["sampleRate"] = t.sampleRate;
    map["bitDepth"] = t.bitDepth;
    map["channels"] = t.channels;
    map["bitrate"] = t.bitrate;
    map["codec"] = QString::fromStdString(t.codec);
    map["artHash"] = QString::fromStdString(t.artHash);
    map["audiophileBadge"] = QString::fromStdString(t.audiophileBadge());
    return map;
}

QHash<int, QByteArray> TrackListModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[FilePathRole] = "filePath";
    roles[TitleRole] = "title";
    roles[ArtistRole] = "artist";
    roles[AlbumRole] = "album";
    roles[AlbumArtistRole] = "albumArtist";
    roles[GenreRole] = "genre";
    roles[YearRole] = "year";
    roles[TrackNumberRole] = "trackNumber";
    roles[DiscNumberRole] = "discNumber";
    roles[DurationMsRole] = "durationMs";
    roles[DurationFormattedRole] = "durationFormatted";
    roles[SampleRateRole] = "sampleRate";
    roles[BitDepthRole] = "bitDepth";
    roles[ChannelsRole] = "channels";
    roles[BitrateRole] = "bitrate";
    roles[CodecRole] = "codec";
    roles[ArtHashRole] = "artHash";
    roles[AudiophileBadgeRole] = "audiophileBadge";
    return roles;
}
