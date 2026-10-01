#include "ThemeLoader.hpp"
#include <QColor>
#include <QDebug>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QStandardPaths>
#include <QUrl>

namespace adapters {

ThemeLoader::ThemeLoader(QObject *parent)
    : QObject(parent), m_tokens(getDefaultDarkStudioTheme()) {

  // Ensure user themes directory exists
  QDir().mkpath(getUserThemesDir());

  setupWatcher();
  refreshAvailableThemes();
}

QString ThemeLoader::getUserThemesDir() const {
  return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) +
         "/themes";
}

void ThemeLoader::setupWatcher() {
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
          [this](const QString &path) {
            qDebug() << "[ThemeLoader] Hot-reloading theme file:" << path;
            // Re-read file upon modification
            loadThemeFromFile(path);
          });

  connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this,
          [this](const QString &path) {
            qDebug() << "[ThemeLoader] Themes directory changed:" << path;
            refreshAvailableThemes();
          });

  QString themesDir = getUserThemesDir();
  if (QDir(themesDir).exists()) {
    m_watcher.addPath(themesDir);
  }
}

void ThemeLoader::watchActiveFile(const QString &filePath) {
  if (!m_activeThemeFilePath.isEmpty()) {
    m_watcher.removePath(m_activeThemeFilePath);
  }
  m_activeThemeFilePath = filePath;
  if (!m_activeThemeFilePath.isEmpty() &&
      QFile::exists(m_activeThemeFilePath)) {
    m_watcher.addPath(m_activeThemeFilePath);
  }
}

ThemeTokens ThemeLoader::getDefaultDarkStudioTheme() {
  ThemeTokens t;
  t.id = "dark-studio";
  t.name = "Dark Studio";
  t.author = "Parakeet";
  t.version = "1.0.0";
  t.apiVersion = "0.1-unstable";
  t.description = "Default dark theme";

  t.background = "#141416";
  t.surface = "#161619";
  t.surfaceElevated = "#1e1e24";
  t.panelBorder = "#24242c";
  t.accent = "#3a82f7";
  t.accentHover = "#5c9eff";
  t.textPrimary = "#ffffff";
  t.textSecondary = "#c0c0d0";
  t.textMuted = "#777788";
  t.selection = "#1f2a3e";
  t.error = "#ff4a4a";
  t.warning = "#f5a623";
  t.success = "#28c840";

  t.fontFamily = "sans-serif";
  t.fontSizeSmall = 9;
  t.fontSizeBase = 11;
  t.fontSizeLarge = 14;
  t.fontSizeTitle = 18;
  t.fontWeightScale = 1.0;
  t.lineHeightScale = 1.2;

  t.spacingSmall = 4;
  t.spacingMedium = 8;
  t.spacingLarge = 16;
  t.cornerRadiusSmall = 2;
  t.cornerRadiusMedium = 4;
  t.panelPadding = 10;
  return t;
}

ThemeTokens ThemeLoader::getBuiltInNordTheme() {
  ThemeTokens t;
  t.id = "nord-audiophile";
  t.name = "Nord";
  t.author = "Parakeet Community";
  t.version = "1.0.0";
  t.apiVersion = "0.1-unstable";
  t.description =
      "Arctic, north-bluish clean palette tailored for night listening";

  t.background = "#2e3440";
  t.surface = "#3b4252";
  t.surfaceElevated = "#434c5e";
  t.panelBorder = "#4c566a";
  t.accent = "#88c0d0";
  t.accentHover = "#8fbcbb";
  t.textPrimary = "#eceff4";
  t.textSecondary = "#d8dee9";
  t.textMuted = "#7e889b";
  t.selection = "#434c5e";
  t.error = "#bf616a";
  t.warning = "#ebcb8b";
  t.success = "#a3be8c";

  t.fontFamily = "sans-serif";
  t.fontSizeSmall = 9;
  t.fontSizeBase = 11;
  t.fontSizeLarge = 14;
  t.fontSizeTitle = 18;
  t.fontWeightScale = 1.0;
  t.lineHeightScale = 1.2;

  t.spacingSmall = 4;
  t.spacingMedium = 8;
  t.spacingLarge = 16;
  t.cornerRadiusSmall = 3;
  t.cornerRadiusMedium = 6;
  t.panelPadding = 12;
  return t;
}

ThemeTokens ThemeLoader::getBuiltInSolarizedDarkTheme() {
  ThemeTokens t;
  t.id = "solarized-dark";
  t.name = "Solarized Dark";
  t.author = "Parakeet Community";
  t.version = "1.0.0";
  t.apiVersion = "0.1-unstable";
  t.description = "Warm low-contrast palette calibrated for eye comfort";

  t.background = "#002b36";
  t.surface = "#073642";
  t.surfaceElevated = "#094452";
  t.panelBorder = "#586e75";
  t.accent = "#268bd2";
  t.accentHover = "#2aa198";
  t.textPrimary = "#fdf6e3";
  t.textSecondary = "#93a1a1";
  t.textMuted = "#657b83";
  t.selection = "#094452";
  t.error = "#dc322f";
  t.warning = "#b58900";
  t.success = "#859900";

  t.fontFamily = "sans-serif";
  t.fontSizeSmall = 9;
  t.fontSizeBase = 11;
  t.fontSizeLarge = 14;
  t.fontSizeTitle = 18;
  t.fontWeightScale = 1.0;
  t.lineHeightScale = 1.2;

  t.spacingSmall = 4;
  t.spacingMedium = 8;
  t.spacingLarge = 16;
  t.cornerRadiusSmall = 3;
  t.cornerRadiusMedium = 6;
  t.panelPadding = 10;
  return t;
}

bool ThemeLoader::validateThemeJson(const QJsonObject &root,
                                    QString &errorReason) {
  if (!root.contains("meta") || !root["meta"].isObject()) {
    errorReason = "Missing required 'meta' object in theme JSON";
    return false;
  }
  QJsonObject meta = root["meta"].toObject();
  for (const char *reqKey : {"name", "author", "version", "apiVersion"}) {
    if (!meta.contains(reqKey) || !meta[reqKey].isString()) {
      errorReason =
          QString("Missing required meta string field: '%1'").arg(reqKey);
      return false;
    }
  }

  if (!root.contains("colors") || !root["colors"].isObject()) {
    errorReason = "Missing required 'colors' object in theme JSON";
    return false;
  }
  QJsonObject colors = root["colors"].toObject();
  const char *reqColors[] = {"background",  "surface",       "surfaceElevated",
                             "panelBorder", "accent",        "accentHover",
                             "textPrimary", "textSecondary", "textMuted",
                             "selection",   "error",         "warning",
                             "success"};
  for (const char *cKey : reqColors) {
    if (!colors.contains(cKey) || !colors[cKey].isString()) {
      errorReason = QString("Missing required color field: '%1'").arg(cKey);
      return false;
    }
    QString colStr = colors[cKey].toString();
    if (!QColor::isValidColorName(colStr)) {
      errorReason =
          QString("Invalid color hex format for '%1': '%2'").arg(cKey, colStr);
      return false;
    }
  }

  return true;
}

ThemeTokens ThemeLoader::parseThemeJson(const QJsonObject &root,
                                        const ThemeTokens &fallback) {
  ThemeTokens t = fallback;

  if (root.contains("meta") && root["meta"].isObject()) {
    QJsonObject meta = root["meta"].toObject();
    if (meta.contains("id") && meta["id"].isString())
      t.id = meta["id"].toString();
    if (meta.contains("name") && meta["name"].isString())
      t.name = meta["name"].toString();
    if (meta.contains("author") && meta["author"].isString())
      t.author = meta["author"].toString();
    if (meta.contains("version") && meta["version"].isString())
      t.version = meta["version"].toString();
    if (meta.contains("apiVersion") && meta["apiVersion"].isString())
      t.apiVersion = meta["apiVersion"].toString();
    if (meta.contains("description") && meta["description"].isString())
      t.description = meta["description"].toString();
  }

  if (root.contains("colors") && root["colors"].isObject()) {
    QJsonObject c = root["colors"].toObject();
    auto readColor = [&](const char *key, QString &target) {
      if (c.contains(key) && c[key].isString()) {
        QString val = c[key].toString();
        if (QColor::isValidColorName(val))
          target = val;
      }
    };
    readColor("background", t.background);
    readColor("surface", t.surface);
    readColor("surfaceElevated", t.surfaceElevated);
    readColor("panelBorder", t.panelBorder);
    readColor("accent", t.accent);
    readColor("accentHover", t.accentHover);
    readColor("textPrimary", t.textPrimary);
    readColor("textSecondary", t.textSecondary);
    readColor("textMuted", t.textMuted);
    readColor("selection", t.selection);
    readColor("error", t.error);
    readColor("warning", t.warning);
    readColor("success", t.success);
  }

  if (root.contains("typography") && root["typography"].isObject()) {
    QJsonObject typo = root["typography"].toObject();
    if (typo.contains("fontFamily") && typo["fontFamily"].isString())
      t.fontFamily = typo["fontFamily"].toString();
    if (typo.contains("fontSizeSmall") && typo["fontSizeSmall"].isDouble())
      t.fontSizeSmall = typo["fontSizeSmall"].toInt();
    if (typo.contains("fontSizeBase") && typo["fontSizeBase"].isDouble())
      t.fontSizeBase = typo["fontSizeBase"].toInt();
    if (typo.contains("fontSizeLarge") && typo["fontSizeLarge"].isDouble())
      t.fontSizeLarge = typo["fontSizeLarge"].toInt();
    if (typo.contains("fontSizeTitle") && typo["fontSizeTitle"].isDouble())
      t.fontSizeTitle = typo["fontSizeTitle"].toInt();
    if (typo.contains("fontWeightScale") && typo["fontWeightScale"].isDouble())
      t.fontWeightScale = typo["fontWeightScale"].toDouble();
    if (typo.contains("lineHeightScale") && typo["lineHeightScale"].isDouble())
      t.lineHeightScale = typo["lineHeightScale"].toDouble();
  }

  if (root.contains("metrics") && root["metrics"].isObject()) {
    QJsonObject m = root["metrics"].toObject();
    if (m.contains("spacingSmall") && m["spacingSmall"].isDouble())
      t.spacingSmall = m["spacingSmall"].toInt();
    if (m.contains("spacingMedium") && m["spacingMedium"].isDouble())
      t.spacingMedium = m["spacingMedium"].toInt();
    if (m.contains("spacingLarge") && m["spacingLarge"].isDouble())
      t.spacingLarge = m["spacingLarge"].toInt();
    if (m.contains("cornerRadiusSmall") && m["cornerRadiusSmall"].isDouble())
      t.cornerRadiusSmall = m["cornerRadiusSmall"].toInt();
    if (m.contains("cornerRadiusMedium") && m["cornerRadiusMedium"].isDouble())
      t.cornerRadiusMedium = m["cornerRadiusMedium"].toInt();
    if (m.contains("panelPadding") && m["panelPadding"].isDouble())
      t.panelPadding = m["panelPadding"].toInt();
  }

  return t;
}

bool ThemeLoader::loadThemeFromFile(const QString &filePath) {
  QFile file(filePath);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    QString err = QString("Cannot open theme file: %1").arg(filePath);
    qWarning() << "[ThemeLoader]" << err;
    emit themeLoadError(err);
    return false;
  }

  QJsonParseError parseError;
  QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
  if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
    QString err = QString("JSON syntax error in %1: %2")
                      .arg(filePath, parseError.errorString());
    qWarning() << "[ThemeLoader]" << err;
    emit themeLoadError(err);
    return false;
  }

  QJsonObject root = doc.object();
  QString validationError;
  if (!validateThemeJson(root, validationError)) {
    qWarning() << "[ThemeLoader] Theme validation failed:" << validationError
               << "Falling back to default.";
    emit themeLoadError(validationError);
    return false;
  }

  // Parse theme with default fallback
  ThemeTokens tokens = parseThemeJson(root, getDefaultDarkStudioTheme());
  if (tokens.id.isEmpty()) {
    tokens.id = QFileInfo(filePath).baseName();
  }

  m_tokens = tokens;
  watchActiveFile(filePath);
  emit themeChanged();
  return true;
}

void ThemeLoader::setThemeId(const QString &id) {
  if (id == "dark-studio") {
    m_tokens = getDefaultDarkStudioTheme();
    watchActiveFile("");
    emit themeChanged();
    return;
  }
  if (id == "nord-audiophile") {
    m_tokens = getBuiltInNordTheme();
    watchActiveFile("");
    emit themeChanged();
    return;
  }
  if (id == "solarized-dark") {
    m_tokens = getBuiltInSolarizedDarkTheme();
    watchActiveFile("");
    emit themeChanged();
    return;
  }

  // Check user themes directory
  QString candidate = getUserThemesDir() + "/" + id + ".json";
  if (QFile::exists(candidate)) {
    if (loadThemeFromFile(candidate)) {
      return;
    }
  }

  // Fall back to default theme
  qWarning() << "[ThemeLoader] Theme id not found or invalid:" << id
             << "- falling back to default.";
  m_tokens = getDefaultDarkStudioTheme();
  watchActiveFile("");
  emit themeChanged();
}

void ThemeLoader::setUiScale(qreal scale) {
  qreal clamped = std::clamp(scale, 0.7, 1.5);
  if (qFuzzyCompare(m_uiScale, clamped))
    return;
  m_uiScale = clamped;
  emit uiScaleChanged();
  emit themeChanged();
}

void ThemeLoader::setDensityPreset(const QString &preset) {
  if (m_densityPreset == preset)
    return;
  m_densityPreset = preset;
  if (preset == "Compact") {
    setUiScale(0.85);
  } else if (preset == "Comfortable") {
    setUiScale(1.15);
  } else {
    setUiScale(1.0); // Standard
  }
}

bool ThemeLoader::installTheme(const QString &sourceFilePath) {
  QString cleanSource = sourceFilePath;
  QUrl url = QUrl::fromUserInput(sourceFilePath);
  if (url.isLocalFile()) {
    cleanSource = url.toLocalFile();
  } else if (cleanSource.startsWith("file://")) {
    cleanSource = cleanSource.mid(7);
  }

  QFileInfo srcInfo(cleanSource);
  if (!srcInfo.exists() || !srcInfo.isFile()) {
    QString err = QString("Theme file does not exist: %1").arg(cleanSource);
    qWarning() << "[ThemeLoader]" << err;
    emit themeLoadError(err);
    return false;
  }

  // Validate before copying
  QFile file(cleanSource);
  if (!file.open(QIODevice::ReadOnly)) {
    emit themeLoadError("Could not read theme file");
    return false;
  }
  QJsonParseError pErr;
  QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &pErr);
  if (pErr.error != QJsonParseError::NoError || !doc.isObject()) {
    emit themeLoadError(
        QString("Invalid theme JSON: %1").arg(pErr.errorString()));
    return false;
  }

  QString valErr;
  if (!validateThemeJson(doc.object(), valErr)) {
    emit themeLoadError(valErr);
    return false;
  }

  QString destPath = getUserThemesDir() + "/" + srcInfo.fileName();
  if (QFile::exists(destPath)) {
    QFile::remove(destPath);
  }

  if (!QFile::copy(cleanSource, destPath)) {
    emit themeLoadError("Failed to copy theme file to user themes folder");
    return false;
  }

  refreshAvailableThemes();
  loadThemeFromFile(destPath);
  return true;
}

void ThemeLoader::openThemesFolder() {
  QDesktopServices::openUrl(QUrl::fromLocalFile(getUserThemesDir()));
}

void ThemeLoader::refreshAvailableThemes() {
  m_availableThemes.clear();

  auto addThemeEntry = [this](const ThemeTokens &t, const QString &path = "") {
    QVariantMap map;
    map["id"] = t.id;
    map["name"] = t.name;
    map["author"] = t.author;
    map["version"] = t.version;
    map["description"] = t.description;
    map["isBuiltIn"] = path.isEmpty();
    map["filePath"] = path;

    QVariantMap colors;
    colors["background"] = t.background;
    colors["surface"] = t.surface;
    colors["surfaceElevated"] = t.surfaceElevated;
    colors["panelBorder"] = t.panelBorder;
    colors["accent"] = t.accent;
    colors["textPrimary"] = t.textPrimary;
    colors["textSecondary"] = t.textSecondary;
    map["colors"] = colors;

    m_availableThemes.append(map);
  };

  // Built-in themes
  addThemeEntry(getDefaultDarkStudioTheme());
  addThemeEntry(getBuiltInNordTheme());
  addThemeEntry(getBuiltInSolarizedDarkTheme());

  // User installed themes
  QDir dir(getUserThemesDir());
  QStringList files =
      dir.entryList(QStringList() << "*.json", QDir::Files, QDir::Name);
  for (const QString &file : files) {
    QString fullPath = dir.absoluteFilePath(file);
    QFile f(fullPath);
    if (f.open(QIODevice::ReadOnly)) {
      QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
      if (doc.isObject()) {
        QJsonObject obj = doc.object();
        QString err;
        if (validateThemeJson(obj, err)) {
          ThemeTokens t = parseThemeJson(obj, getDefaultDarkStudioTheme());
          if (t.id.isEmpty())
            t.id = QFileInfo(file).baseName();
          addThemeEntry(t, fullPath);
        }
      }
    }
  }

  emit availableThemesChanged();
}

} // namespace adapters
