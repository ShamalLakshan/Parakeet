#include "TrackListModel.hpp"
#include "core/ports/IMusicDatabasePort.hpp"

TrackListModel::TrackListModel(core::IMusicDatabasePort *dbPort,
                               QObject *parent)
    : QAbstractListModel(parent), m_dbPort(dbPort) {
  if (m_dbPort) {
    loadAllTracks();
  }
}

void TrackListModel::setDatabasePort(core::IMusicDatabasePort *dbPort) {
  m_dbPort = dbPort;
}

void TrackListModel::setTracks(const std::vector<core::Track> &tracks) {
  beginResetModel();
  m_allTracks = tracks;
  m_filteredTracks = tracks;
  m_filterText.clear();
  m_selectedIndices.clear();
  endResetModel();
  emit countChanged();
  emit selectionChanged();
}

void TrackListModel::loadAllTracks() {
  beginResetModel();
  m_allTracks.clear();
  m_filteredTracks.clear();
  m_selectedIndices.clear();
  if (m_dbPort) {
    m_allTracks = m_dbPort->getAllTracks();
  }
  applyFilter();
  endResetModel();
  emit countChanged();
  emit selectionChanged();
}

void TrackListModel::loadAlbumTracks(const QString &albumTitle,
                                     const QString &albumArtist) {
  beginResetModel();
  m_allTracks.clear();
  m_filteredTracks.clear();
  m_selectedIndices.clear();
  if (m_dbPort) {
    m_allTracks = m_dbPort->getTracksByAlbum(albumTitle.toStdString(),
                                             albumArtist.toStdString());
  }
  applyFilter();
  endResetModel();
  emit countChanged();
  emit selectionChanged();
}

void TrackListModel::setFilter(const QString &filterText) {
  if (m_filterText == filterText)
    return;
  m_filterText = filterText;
  beginResetModel();
  m_selectedIndices.clear();
  applyFilter();
  endResetModel();
  emit countChanged();
  emit selectionChanged();
}

void TrackListModel::applyFilter() {
  if (m_filterText.trimmed().isEmpty()) {
    m_filteredTracks = m_allTracks;
    return;
  }

  m_filteredTracks.clear();
  QString lower = m_filterText.toLower();
  for (const auto &t : m_allTracks) {
    QString title = QString::fromStdString(t.title).toLower();
    QString artist = QString::fromStdString(t.artist).toLower();
    QString album = QString::fromStdString(t.album).toLower();
    QString genre = QString::fromStdString(t.genre).toLower();
    if (title.contains(lower) || artist.contains(lower) ||
        album.contains(lower) || genre.contains(lower)) {
      m_filteredTracks.push_back(t);
    }
  }
}

int TrackListModel::rowCount(const QModelIndex &parent) const {
  if (parent.isValid())
    return 0;
  return static_cast<int>(m_filteredTracks.size());
}

QVariant TrackListModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() < 0 ||
      index.row() >= static_cast<int>(m_filteredTracks.size())) {
    return QVariant();
  }

  const auto &track = m_filteredTracks[static_cast<size_t>(index.row())];

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
  case IsSelectedRole:
    return m_selectedIndices.find(index.row()) != m_selectedIndices.end();
  default:
    return QVariant();
  }
}

QVariantMap TrackListModel::getTrackAt(int index) const {
  QVariantMap map;
  if (index < 0 || index >= static_cast<int>(m_filteredTracks.size())) {
    return map;
  }
  const auto &t = m_filteredTracks[static_cast<size_t>(index)];
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
  map["isSelected"] = m_selectedIndices.find(index) != m_selectedIndices.end();
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
  roles[IsSelectedRole] = "isSelected";
  return roles;
}

void TrackListModel::selectAll() {
  if (m_filteredTracks.empty())
    return;
  m_selectedIndices.clear();
  for (size_t i = 0; i < m_filteredTracks.size(); ++i) {
    m_selectedIndices.insert(static_cast<int>(i));
  }
  emit dataChanged(
      createIndex(0, 0),
      createIndex(static_cast<int>(m_filteredTracks.size()) - 1, 0),
      {IsSelectedRole});
  emit selectionChanged();
}

void TrackListModel::invertSelection() {
  if (m_filteredTracks.empty())
    return;
  std::unordered_set<int> inverted;
  for (size_t i = 0; i < m_filteredTracks.size(); ++i) {
    int idx = static_cast<int>(i);
    if (m_selectedIndices.find(idx) == m_selectedIndices.end()) {
      inverted.insert(idx);
    }
  }
  m_selectedIndices = std::move(inverted);
  emit dataChanged(
      createIndex(0, 0),
      createIndex(static_cast<int>(m_filteredTracks.size()) - 1, 0),
      {IsSelectedRole});
  emit selectionChanged();
}

void TrackListModel::clearSelection() {
  if (m_selectedIndices.empty())
    return;
  m_selectedIndices.clear();
  emit dataChanged(
      createIndex(0, 0),
      createIndex(static_cast<int>(m_filteredTracks.size()) - 1, 0),
      {IsSelectedRole});
  emit selectionChanged();
}

void TrackListModel::selectRange(int fromIndex, int toIndex) {
  if (m_filteredTracks.empty())
    return;
  int maxIdx = static_cast<int>(m_filteredTracks.size()) - 1;
  int start = std::clamp(std::min(fromIndex, toIndex), 0, maxIdx);
  int end = std::clamp(std::max(fromIndex, toIndex), 0, maxIdx);
  for (int i = start; i <= end; ++i) {
    m_selectedIndices.insert(i);
  }
  emit dataChanged(createIndex(start, 0), createIndex(end, 0),
                   {IsSelectedRole});
  emit selectionChanged();
}

void TrackListModel::toggleSelection(int index) {
  if (index < 0 || index >= static_cast<int>(m_filteredTracks.size()))
    return;
  auto it = m_selectedIndices.find(index);
  if (it != m_selectedIndices.end()) {
    m_selectedIndices.erase(it);
  } else {
    m_selectedIndices.insert(index);
  }
  emit dataChanged(createIndex(index, 0), createIndex(index, 0),
                   {IsSelectedRole});
  emit selectionChanged();
}

void TrackListModel::setRowSelected(int index, bool selected) {
  if (index < 0 || index >= static_cast<int>(m_filteredTracks.size()))
    return;
  if (selected) {
    m_selectedIndices.insert(index);
  } else {
    m_selectedIndices.erase(index);
  }
  emit dataChanged(createIndex(index, 0), createIndex(index, 0),
                   {IsSelectedRole});
  emit selectionChanged();
}

bool TrackListModel::isSelected(int index) const {
  return m_selectedIndices.find(index) != m_selectedIndices.end();
}

int TrackListModel::selectedCount() const {
  return static_cast<int>(m_selectedIndices.size());
}

QVariantList TrackListModel::getSelectedTrackIds() const {
  QVariantList list;
  for (int idx : m_selectedIndices) {
    if (idx >= 0 && idx < static_cast<int>(m_filteredTracks.size())) {
      list.append(QString::fromStdString(
          m_filteredTracks[static_cast<size_t>(idx)].id));
    }
  }
  return list;
}

QVariantList TrackListModel::getSelectedTracks() const {
  QVariantList list;
  for (int idx : m_selectedIndices) {
    if (idx >= 0 && idx < static_cast<int>(m_filteredTracks.size())) {
      list.append(getTrackAt(idx));
    }
  }
  return list;
}

void TrackListModel::removeSelected() {
  if (m_selectedIndices.empty())
    return;

  std::vector<core::Track> remainingTracks;
  remainingTracks.reserve(m_filteredTracks.size());
  for (size_t i = 0; i < m_filteredTracks.size(); ++i) {
    if (m_selectedIndices.find(static_cast<int>(i)) ==
        m_selectedIndices.end()) {
      remainingTracks.push_back(m_filteredTracks[i]);
    }
  }
  setTracks(remainingTracks);
}
