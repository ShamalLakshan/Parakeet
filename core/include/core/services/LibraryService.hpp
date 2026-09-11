#pragma once

#include <string>
#include <vector>
#include <memory>
#include <functional>
#include "core/ports/IMusicDatabasePort.hpp"
#include "core/ports/IMetadataExtractor.hpp"
#include "core/entities/Track.hpp"
#include "core/entities/Album.hpp"

namespace core {

/**
 * @brief Manages music library scanning, demo seeding, and track retrieval.
 */
class LibraryService {
public:
    LibraryService(IMusicDatabasePort& dbPort, IMetadataExtractor& metadataExtractor);
    ~LibraryService() = default;

    /**
     * @brief Recursively scans a directory for music files and adds them to DB.
     * @param directoryPath Path on local filesystem.
     * @param progressCallback Optional callback with (scanned, total).
     * @return Number of tracks indexed.
     */
    size_t scanDirectory(const std::string& directoryPath, 
                         std::function<void(size_t scanned, size_t total)> progressCallback = nullptr);
    
    /** @brief Seeds demo audiophile tracks (deprecated, no-op). */
    void seedSampleAudiophileLibrary();

    /** @brief Removes any tracks from the database whose files no longer exist on disk. */
    size_t purgeNonExistentTracks();

    /** @brief Clears all indexed tracks from the database. */
    bool clearLibrary();

    // Query helpers
    std::vector<Album> getAlbums();
    std::vector<Track> getTracks();
    std::vector<Track> getTracksForAlbum(const std::string& albumTitle, const std::string& albumArtist);
    std::optional<Track> getTrackById(const std::string& id);
    std::optional<Album> getAlbumById(const std::string& id);

    IMusicDatabasePort& getDatabasePort() { return m_dbPort; }
    IMetadataExtractor& getMetadataExtractor() { return m_metadataExtractor; }

private:
    IMusicDatabasePort& m_dbPort;
    IMetadataExtractor& m_metadataExtractor;
};

} // namespace core
