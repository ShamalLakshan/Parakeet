#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <QDir>
#include <memory>

#include "core/services/PlayerService.hpp"
#include "core/services/LibraryService.hpp"
#include "storage/SqliteDatabaseAdapter.hpp"
#include "metadata/TagLibMetadataAdapter.hpp"
#include "audio/BitPerfectAudioAdapter.hpp"
#include "providers/AlbumArtImageProvider.hpp"
#include "theming/ThemeLoader.hpp"
#include "QtBridge.hpp"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setOrganizationName("ParakeetAudio");
    app.setApplicationName("Parakeet");

    // SQLite database in app data folder
    QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataDir);
    QString dbPath = appDataDir + "/parakeet_library.db";

    auto dbAdapter = std::make_unique<adapters::SqliteDatabaseAdapter>();
    dbAdapter->initialize(dbPath.toStdString());

    // Metadata and audio adapters
    auto metadataAdapter = std::make_unique<adapters::TagLibMetadataAdapter>();
    auto audioEngine = std::make_shared<adapters::BitPerfectAudioAdapter>();
    audioEngine->initialize(96000, 2);

    // Core services
    core::LibraryService libraryService(*dbAdapter, *metadataAdapter);
    core::PlayerService playerService(audioEngine);

    // Theming engine
    auto themeLoader = std::make_unique<adapters::ThemeLoader>();

    // Bridge connecting core to QML
    QtBridge bridge(playerService, libraryService, themeLoader.get());

    // Play next track when current one finishes
    audioEngine->setEndOfTrackCallback([&bridge]() {
        QMetaObject::invokeMethod(&bridge, "nextTrack", Qt::QueuedConnection);
    });

    // QML engine and album art provider
    QString coversDir = appDataDir + "/covers";
    QQmlApplicationEngine engine;
    engine.addImageProvider("albumart", new AlbumArtImageProvider(metadataAdapter.get(), dbAdapter.get(), coversDir));
    engine.rootContext()->setContextProperty("Theme", themeLoader.get());
    engine.rootContext()->setContextProperty("bridge", &bridge);
    
    const QUrl url(QStringLiteral("qrc:/PlayerUI/ui_qt/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
