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
#include "QtBridge.hpp"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setOrganizationName("ParakeetAudio");
    app.setApplicationName("Parakeet");

    // set up sqlite db in the app data folder
    QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataDir);
    QString dbPath = appDataDir + "/parakeet_library.db";

    auto dbAdapter = std::make_unique<adapters::SqliteDatabaseAdapter>();
    dbAdapter->initialize(dbPath.toStdString());

    // metadata parser and audio engine adapters
    auto metadataAdapter = std::make_unique<adapters::TagLibMetadataAdapter>();
    auto audioEngine = std::make_shared<adapters::BitPerfectAudioAdapter>();
    audioEngine->initialize(96000, 2);

    // pure core services with zero qt dependencies
    core::LibraryService libraryService(*dbAdapter, *metadataAdapter);
    core::PlayerService playerService(audioEngine);

    // bridge connecting core to qml
    QtBridge bridge(playerService, libraryService);

    // automatic queue progression on track end
    audioEngine->setEndOfTrackCallback([&bridge]() {
        QMetaObject::invokeMethod(&bridge, "nextTrack", Qt::QueuedConnection);
    });

    // qml engine and custom album art provider with persistent disk cache
    QString coversDir = appDataDir + "/covers";
    QQmlApplicationEngine engine;
    engine.addImageProvider("albumart", new AlbumArtImageProvider(metadataAdapter.get(), dbAdapter.get(), coversDir));
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
