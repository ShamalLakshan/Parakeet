#include "AlbumListModel.hpp"
#include "core/ports/IMusicDatabasePort.hpp"
#include <algorithm>

AlbumListModel::AlbumListModel(core::IMusicDatabasePort *dbPort,
                               QObject *parent)
    : QAbstractListModel(parent), m_dbPort(dbPort) {
  if (m_dbPort) {
    reload();
  }
}

void AlbumListModel::setDatabasePort(core::IMusicDatabasePort *dbPort) {
  m_dbPort = dbPort;
  reload();
}

void AlbumListModel::reload() {
  beginResetModel();
  m_allAlbums.clear();
  m_filteredAlbums.clear();
  if (m_dbPort) {
    m_allAlbums = m_dbPort->getAllAlbums();
  }
  applyFilter();
  endResetModel();
  emit countChanged();
}

void AlbumListModel::setFilter(const QString &filterText) {
  if (m_filterText == filterText)
    return;
  m_filterText = filterText;
  beginResetModel();
  applyFilter();
  endResetModel();
  emit countChanged();
}

void AlbumListModel::applyFilter() {
  if (m_filterText.trimmed().isEmpty()) {
    m_filteredAlbums = m_allAlbums;
    return;
  }

  m_filteredAlbums.clear();
  QString lower = m_filterText.toLower();
  for (const auto &a : m_allAlbums) {
    QString title = QString::fromStdString(a.title).toLower();
    QString artist = QString::fromStdString(a.artist).toLower();
    QString genre = QString::fromStdString(a.genre).toLower();
    if (title.contains(lower) || artist.contains(lower) ||
        genre.contains(lower)) {
      m_filteredAlbums.push_back(a);
    }
  }
}

int AlbumListModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid())
    return 0;
  return static_cast<int>(m_filteredAlbums.size());
}

QVariant AlbumListModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() < 0 ||
      index.row() >= static_cast<int>(m_filteredAlbums.size())) {
    return QVariant();
  }

  const auto &album = m_filteredAlbums[static_cast<size_t>(index.row())];

  switch (role) {
  case IdRole:
    return QString::fromStdString(album.id);
  case TitleRole:
    return QString::fromStdString(album.title);
  case ArtistRole:
    return QString::fromStdString(album.artist);
  case YearRole:
    return album.year > 0 ? QVariant(album.year) : QVariant();
  case GenreRole:
    return QString::fromStdString(album.genre);
  case TrackCountRole:
    return album.trackCount;
  case DurationRole:
    return QString::fromStdString(album.durationFormatted());
  case ArtHashRole:
    return QString::fromStdString(album.artHash);
  case CodecRole:
    return QString::fromStdString(album.primaryCodec);
  case SampleRateRole:
    return album.maxSampleRate;
  case BitDepthRole:
    return album.maxBitDepth;
  case QualityBadgeRole:
    return QString::fromStdString(album.qualityBadge);
  case AudiophileSummaryRole:
    return QString::fromStdString(album.audiophileSummary());
  default:
    return QVariant();
  }
}

QHash<int, QByteArray> AlbumListModel::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[IdRole] = "id";
  roles[TitleRole] = "title";
  roles[ArtistRole] = "artist";
  roles[YearRole] = "year";
  roles[GenreRole] = "genre";
  roles[TrackCountRole] = "trackCount";
  roles[DurationRole] = "durationFormatted";
  roles[ArtHashRole] = "artHash";
  roles[CodecRole] = "codec";
  roles[SampleRateRole] = "sampleRate";
  roles[BitDepthRole] = "bitDepth";
  roles[QualityBadgeRole] = "qualityBadge";
  roles[AudiophileSummaryRole] = "audiophileSummary";
  return roles;
}

QVariantMap AlbumListModel::getAlbumAt(int index) const {
  QVariantMap map;
  if (index < 0 || index >= static_cast<int>(m_filteredAlbums.size())) {
    return map;
  }
  const auto &album = m_filteredAlbums[static_cast<size_t>(index)];
  map["id"] = QString::fromStdString(album.id);
  map["title"] = QString::fromStdString(album.title);
  map["artist"] = QString::fromStdString(album.artist);
  map["year"] = album.year;
  map["genre"] = QString::fromStdString(album.genre);
  map["trackCount"] = album.trackCount;
  map["durationFormatted"] = QString::fromStdString(album.durationFormatted());
  map["artHash"] = QString::fromStdString(album.artHash);
  map["codec"] = QString::fromStdString(album.primaryCodec);
  map["sampleRate"] = album.maxSampleRate;
  map["bitDepth"] = album.maxBitDepth;
  map["qualityBadge"] = QString::fromStdString(album.qualityBadge);
  map["audiophileSummary"] = QString::fromStdString(album.audiophileSummary());
  return map;
}
