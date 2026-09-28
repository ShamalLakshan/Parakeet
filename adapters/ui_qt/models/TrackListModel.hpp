#pragma once

#include "core/entities/Track.hpp"
#include <QAbstractListModel>
#include <memory>
#include <unordered_set>
#include <vector>

namespace core {
class IMusicDatabasePort;
}

/**
 * @brief Qt List Model for displaying tracks in library views and album detail
 * popups.
 */
class TrackListModel : public QAbstractListModel {
  Q_OBJECT
  Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
  Q_PROPERTY(int selectedCount READ selectedCount NOTIFY selectionChanged)

public:
  enum TrackRoles {
    IdRole = Qt::UserRole + 1,
    FilePathRole,
    TitleRole,
    ArtistRole,
    AlbumRole,
    AlbumArtistRole,
    GenreRole,
    YearRole,
    TrackNumberRole,
    DiscNumberRole,
    DurationMsRole,
    DurationFormattedRole,
    SampleRateRole,
    BitDepthRole,
    ChannelsRole,
    BitrateRole,
    CodecRole,
    ArtHashRole,
    AudiophileBadgeRole,
    IsSelectedRole
  };

  explicit TrackListModel(core::IMusicDatabasePort *dbPort = nullptr,
                          QObject *parent = nullptr);
  ~TrackListModel() override = default;

  void setDatabasePort(core::IMusicDatabasePort *dbPort);
  void setTracks(const std::vector<core::Track> &tracks);
  [[nodiscard]] const std::vector<core::Track> &tracks() const {
    return m_filteredTracks;
  }

  [[nodiscard]] int
  rowCount(const QModelIndex &parent = QModelIndex()) const override;
  [[nodiscard]] QVariant data(const QModelIndex &index,
                              int role = Qt::DisplayRole) const override;
  [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

  Q_INVOKABLE void loadAllTracks();
  Q_INVOKABLE void loadAlbumTracks(const QString &albumTitle,
                                   const QString &albumArtist);
  Q_INVOKABLE void setFilter(const QString &filterText);
  [[nodiscard]] Q_INVOKABLE QVariantMap getTrackAt(int index) const;

  // Selection management
  Q_INVOKABLE void selectAll();
  Q_INVOKABLE void invertSelection();
  Q_INVOKABLE void clearSelection();
  Q_INVOKABLE void selectRange(int fromIndex, int toIndex);
  Q_INVOKABLE void toggleSelection(int index);
  Q_INVOKABLE void setRowSelected(int index, bool selected);
  [[nodiscard]] Q_INVOKABLE bool isSelected(int index) const;
  [[nodiscard]] Q_INVOKABLE int selectedCount() const;
  [[nodiscard]] Q_INVOKABLE QVariantList getSelectedTrackIds() const;
  [[nodiscard]] Q_INVOKABLE QVariantList getSelectedTracks() const;
  Q_INVOKABLE void removeSelected();

signals:
  void countChanged();
  void selectionChanged();

private:
  void applyFilter();

  core::IMusicDatabasePort *m_dbPort{nullptr};
  std::vector<core::Track> m_allTracks;
  std::vector<core::Track> m_filteredTracks;
  std::unordered_set<int> m_selectedIndices;
  QString m_filterText;
};
