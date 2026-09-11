#include "AlbumArtImageProvider.hpp"
#include <QPainter>
#include <QPainterPath>
#include <QFont>
#include <QPen>
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <iostream>

AlbumArtImageProvider::AlbumArtImageProvider(core::IMetadataExtractor* extractor,
                                             core::IMusicDatabasePort* dbPort,
                                             const QString& cacheDir)
    : QQuickImageProvider(QQuickImageProvider::Pixmap),
      m_extractor(extractor),
      m_dbPort(dbPort),
      m_cacheDir(cacheDir) {
    if (!m_cacheDir.isEmpty()) {
        QDir().mkpath(m_cacheDir);
    }
}

void AlbumArtImageProvider::setExtractor(core::IMetadataExtractor* extractor) {
    m_extractor = extractor;
}

void AlbumArtImageProvider::setDatabasePort(core::IMusicDatabasePort* dbPort) {
    m_dbPort = dbPort;
}

void AlbumArtImageProvider::setCacheDir(const QString& cacheDir) {
    m_cacheDir = cacheDir;
    if (!m_cacheDir.isEmpty()) {
        QDir().mkpath(m_cacheDir);
    }
}

void AlbumArtImageProvider::cacheArtwork(const QString& artHash, const QByteArray& data) {
    QPixmap pix;
    if (pix.loadFromData(data)) {
        m_pixmapCache[artHash.toStdString()] = pix;
        if (!m_cacheDir.isEmpty()) {
            QString outPath = m_cacheDir + "/" + artHash + ".jpg";
            QFile file(outPath);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(data);
                file.close();
            }
        }
    }
}

QPixmap AlbumArtImageProvider::requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) {
    int w = requestedSize.width() > 0 ? requestedSize.width() : 300;
    int h = requestedSize.height() > 0 ? requestedSize.height() : 300;

    if (size) {
        *size = QSize(w, h);
    }

    if (id.isEmpty() || id == "default") {
        return generatePlaceholder("default", w, h);
    }

    std::string key = id.toStdString();

    // 1. In-memory cache
    auto it = m_pixmapCache.find(key);
    if (it != m_pixmapCache.end()) {
        return it->second.scaled(w, h, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
    }

    // 2. Disk cache
    if (!m_cacheDir.isEmpty()) {
        QString diskPathJpg = m_cacheDir + "/" + id + ".jpg";
        QString diskPathPng = m_cacheDir + "/" + id + ".png";
        QString path = QFile::exists(diskPathJpg) ? diskPathJpg : (QFile::exists(diskPathPng) ? diskPathPng : "");
        if (!path.isEmpty()) {
            QPixmap pix;
            if (pix.load(path)) {
                m_pixmapCache[key] = pix;
                return pix.scaled(w, h, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
            }
        }
    }

    // 3. Extract from database track matching artHash or id
    if (m_dbPort && m_extractor) {
        auto allTracks = m_dbPort->getAllTracks();
        for (const auto& t : allTracks) {
            if (t.artHash == key || t.id == key || t.filePath == key) {
                auto artOpt = m_extractor->extractArtwork(t.filePath);
                if (artOpt.has_value() && !artOpt->data.empty()) {
                    QByteArray bytes(reinterpret_cast<const char*>(artOpt->data.data()), static_cast<int>(artOpt->data.size()));
                    QPixmap pix;
                    if (pix.loadFromData(bytes)) {
                        m_pixmapCache[key] = pix;
                        if (!m_cacheDir.isEmpty()) {
                            QString diskPath = m_cacheDir + "/" + id + ".jpg";
                            QFile file(diskPath);
                            if (file.open(QIODevice::WriteOnly)) {
                                file.write(bytes);
                                file.close();
                            }
                        }
                        return pix.scaled(w, h, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
                    }
                }
                break;
            }
        }
    }

    // 4. Elegant, deslopped monochrome placeholder
    return generatePlaceholder(id, w, h);
}

QPixmap AlbumArtImageProvider::generatePlaceholder(const QString& id, int width, int height) {
    QPixmap pix(width, height);
    pix.fill(QColor(24, 24, 28)); // Solid dark slate

    QPainter p(&pix);
    p.setRenderHint(QPainter::Antialiasing);
    p.setRenderHint(QPainter::TextAntialiasing);

    // Subtle 1px inner border
    p.setPen(QPen(QColor(42, 42, 50), 1));
    p.setBrush(Qt::NoBrush);
    p.drawRect(0, 0, width - 1, height - 1);

    int cx = width / 2;
    int cy = height / 2;

    // Crisp monochrome vinyl / disc motif (solid tones, no gradients)
    int radius = qMin(width, height) / 3;
    if (radius > 15) {
        p.setPen(QPen(QColor(36, 36, 44), 1.5));
        p.setBrush(QColor(20, 20, 24));
        p.drawEllipse(QPoint(cx, cy - 8), radius, radius);

        p.setPen(QPen(QColor(48, 48, 58), 1));
        p.setBrush(Qt::NoBrush);
        p.drawEllipse(QPoint(cx, cy - 8), radius - 8, radius - 8);
        p.drawEllipse(QPoint(cx, cy - 8), radius - 16, radius - 16);

        // Center hub
        p.setPen(Qt::NoPen);
        p.setBrush(QColor(60, 60, 72));
        p.drawEllipse(QPoint(cx, cy - 8), 10, 10);

        // Spindle hole
        p.setBrush(QColor(24, 24, 28));
        p.drawEllipse(QPoint(cx, cy - 8), 4, 4);
    }

    // Clean, understated typography
    p.setPen(QColor(110, 110, 125));
    QFont font("Inter", 8, QFont::DemiBold);
    font.setLetterSpacing(QFont::AbsoluteSpacing, 1.2);
    p.setFont(font);
    p.drawText(QRect(8, height - 26, width - 16, 18), Qt::AlignCenter, "PARAKEET");

    return pix;
}
