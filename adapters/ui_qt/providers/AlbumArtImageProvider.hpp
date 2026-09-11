#pragma once

#include <QQuickImageProvider>
#include <QPixmap>
#include <QPainter>
#include <QString>
#include <memory>
#include <unordered_map>
#include "core/ports/IMetadataExtractor.hpp"
#include "core/ports/IMusicDatabasePort.hpp"

/**
 * @brief Clean, high-performance album art provider with disk caching and elegant monochrome fallback.
 */
class AlbumArtImageProvider : public QQuickImageProvider {
public:
    explicit AlbumArtImageProvider(core::IMetadataExtractor* extractor = nullptr,
                                  core::IMusicDatabasePort* dbPort = nullptr,
                                  const QString& cacheDir = QString());
    ~AlbumArtImageProvider() override = default;

    QPixmap requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) override;

    void setExtractor(core::IMetadataExtractor* extractor);
    void setDatabasePort(core::IMusicDatabasePort* dbPort);
    void setCacheDir(const QString& cacheDir);
    void cacheArtwork(const QString& artHash, const QByteArray& data);

private:
    QPixmap generatePlaceholder(const QString& id, int width, int height);

    core::IMetadataExtractor* m_extractor{nullptr};
    core::IMusicDatabasePort* m_dbPort{nullptr};
    QString m_cacheDir;
    std::unordered_map<std::string, QPixmap> m_pixmapCache;
};
