#include <QApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <memory>

#include "QtBridge.hpp"
#include "audio/BitPerfectAudioAdapter.hpp"
#include "core/services/LibraryService.hpp"
#include "core/services/PlayerService.hpp"
#include "metadata/TagLibMetadataAdapter.hpp"
#include "providers/AlbumArtImageProvider.hpp"
#include "storage/SqliteDatabaseAdapter.hpp"
#include "theming/ThemeLoader.hpp"

int main(int argc, char *argv[]) {
  QApplication app(argc, argv);
  app.setOrganizationName("ParakeetAudio");
  app.setApplicationName("Parakeet");

  // Determine application data directory (support portable mode & AppImage)
  QString baseDir;
  if (qEnvironmentVariableIsSet("APPIMAGE")) {
    baseDir = QFileInfo(qEnvironmentVariable("APPIMAGE")).absolutePath();
  } else {
    baseDir = QCoreApplication::applicationDirPath();
  }

  const QString portableDir = baseDir + "/data";
  const bool isPortable = QFile::exists(baseDir + "/portable.dat") ||
                          QDir(portableDir).exists() ||
                          app.arguments().contains("--portable") ||
                          qEnvironmentVariableIsSet("PARAKEET_PORTABLE");

  QString appDataDir;
  if (isPortable) {
    appDataDir = portableDir;
    QDir().mkpath(appDataDir);
    qputenv("PARAKEET_PORTABLE", "1");
    qputenv("PARAKEET_DATA_DIR", portableDir.toUtf8());
    qputenv("XDG_DATA_HOME", (portableDir + "/share").toUtf8());
    qputenv("XDG_CONFIG_HOME", (portableDir + "/config").toUtf8());
    qputenv("XDG_CACHE_HOME", (portableDir + "/cache").toUtf8());
  } else {
    appDataDir =
        QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataDir);
  }
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

  // Restore playback session according to startup action preferences
  bridge.restorePlaybackSession();

  // QML engine and album art provider
  QString coversDir = appDataDir + "/covers";
  QQmlApplicationEngine engine;
  engine.addImageProvider(
      "albumart", new AlbumArtImageProvider(metadataAdapter.get(),
                                            dbAdapter.get(), coversDir));
  engine.rootContext()->setContextProperty("Theme", themeLoader.get());
  engine.rootContext()->setContextProperty("bridge", &bridge);

  const QUrl url(QStringLiteral("qrc:/PlayerUI/ui_qt/qml/Main.qml"));
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
          QCoreApplication::exit(-1);
      },
      Qt::QueuedConnection);

  engine.load(url);

  return app.exec();
}
