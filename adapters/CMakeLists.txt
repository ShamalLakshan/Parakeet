find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Multimedia)
find_package(PkgConfig REQUIRED)
pkg_check_modules(SQLITE REQUIRED sqlite3)
pkg_check_modules(TAGLIB REQUIRED taglib)

# UI, Theming, Data & Audio Adapters
qt_add_library(ui_adapter STATIC
    ui_qt/QtBridge.hpp
    ui_qt/QtBridge.cpp
    ui_qt/theming/ThemeLoader.hpp
    ui_qt/theming/ThemeLoader.cpp
    ui_qt/models/AlbumListModel.hpp
    ui_qt/models/AlbumListModel.cpp
    ui_qt/models/TrackListModel.hpp
    ui_qt/models/TrackListModel.cpp
    ui_qt/providers/AlbumArtImageProvider.hpp
    ui_qt/providers/AlbumArtImageProvider.cpp
    metadata/TagLibMetadataAdapter.hpp
    metadata/TagLibMetadataAdapter.cpp
    storage/SqliteDatabaseAdapter.hpp
    storage/SqliteDatabaseAdapter.cpp
    audio/BitPerfectAudioAdapter.hpp
    audio/BitPerfectAudioAdapter.cpp
)

qt_add_qml_module(ui_adapter
    URI PlayerUI
    VERSION 1.0
    QML_FILES
        ui_qt/qml/Main.qml
        ui_qt/qml/VectorIcon.qml
        ui_qt/qml/components/Badge.qml
        ui_qt/qml/components/ContextMenu.qml
        ui_qt/qml/dialogs/PreferencesDialog.qml
        ui_qt/qml/views/QueueView.qml
)

target_link_libraries(ui_adapter PUBLIC
    player_core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    ${SQLITE_LIBRARIES}
    ${TAGLIB_LIBRARIES}
)

target_include_directories(ui_adapter PUBLIC 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/ui_qt
    ${CMAKE_CURRENT_SOURCE_DIR}/ui_qt/theming
    ${CMAKE_CURRENT_SOURCE_DIR}/ui_qt/models
    ${CMAKE_CURRENT_SOURCE_DIR}/ui_qt/providers
    ${CMAKE_CURRENT_SOURCE_DIR}/metadata
    ${CMAKE_CURRENT_SOURCE_DIR}/storage
    ${CMAKE_CURRENT_SOURCE_DIR}/audio
    ${SQLITE_INCLUDE_DIRS}
    ${TAGLIB_INCLUDE_DIRS}
)
