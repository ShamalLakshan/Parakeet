#pragma once

#include <QAbstractListModel>
#include <vector>
#include <memory>
#include "core/entities/Track.hpp"

namespace core {
class IMusicDatabasePort;
}

/**
 * @brief Qt List Model for displaying tracks in library views and album detail popups.
 */
class TrackListModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

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
        AudiophileBadgeRole
    };

    explicit TrackListModel(core::IMusicDatabasePort* dbPort = nullptr, QObject* parent = nullptr);
    ~TrackListModel() override = default;

    void setDatabasePort(core::IMusicDatabasePort* dbPort);
    void setTracks(const std::vector<core::Track>& tracks);

    [[nodiscard]] int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    [[nodiscard]] QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void loadAllTracks();
    Q_INVOKABLE void loadAlbumTracks(const QString& albumTitle, const QString& albumArtist);
    Q_INVOKABLE void setFilter(const QString& filterText);
    Q_INVOKABLE QVariantMap getTrackAt(int index) const;

signals:
    void countChanged();

private:
    void applyFilter();

    core::IMusicDatabasePort* m_dbPort{nullptr};
    std::vector<core::Track> m_allTracks;
    std::vector<core::Track> m_filteredTracks;
    QString m_filterText;
};
