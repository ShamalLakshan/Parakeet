#pragma once

#include <QAbstractListModel>
#include <vector>
#include <memory>
#include "core/entities/Album.hpp"

namespace core {
class IMusicDatabasePort;
}

/**
 * @brief Qt List Model for displaying and filtering album cards in QML GridView.
 */
class AlbumListModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum AlbumRoles {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        ArtistRole,
        YearRole,
        GenreRole,
        TrackCountRole,
        DurationRole,
        ArtHashRole,
        CodecRole,
        SampleRateRole,
        BitDepthRole,
        QualityBadgeRole,
        AudiophileSummaryRole
    };

    explicit AlbumListModel(core::IMusicDatabasePort* dbPort = nullptr, QObject* parent = nullptr);
    ~AlbumListModel() override = default;

    void setDatabasePort(core::IMusicDatabasePort* dbPort);

    [[nodiscard]] int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    [[nodiscard]] QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void setFilter(const QString& filterText);

signals:
    void countChanged();

private:
    void applyFilter();

    core::IMusicDatabasePort* m_dbPort{nullptr};
    std::vector<core::Album> m_allAlbums;
    std::vector<core::Album> m_filteredAlbums;
    QString m_filterText;
};
