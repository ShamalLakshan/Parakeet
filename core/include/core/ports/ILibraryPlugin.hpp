#pragma once

#include <cstdint>
#include <string>
#include <optional>
#include "core/entities/Track.hpp"

namespace core {

/**
 * @brief Plugin interface for library extensions (metadata, lyrics, scrobbling).
 */
class ILibraryPlugin {
public:
    virtual ~ILibraryPlugin() = default;

    [[nodiscard]] virtual const char* getName() const noexcept = 0;
    [[nodiscard]] virtual const char* getVersion() const noexcept = 0;
    [[nodiscard]] virtual const char* getDescription() const noexcept = 0;

    virtual bool initialize() = 0;
    virtual void shutdown() = 0;

    /**
     * @brief Enrich track metadata (tags, covers, external IDs).
     */
    virtual std::optional<Track> enrichMetadata(const Track& track) {
        (void)track;
        return std::nullopt;
    }

    /**
     * @brief Fetch lyrics for a track.
     */
    virtual std::string fetchLyrics(const std::string& artist, const std::string& title) {
        (void)artist;
        (void)title;
        return "";
    }

    /**
     * @brief Called when a track finishes playing (e.g. for scrobbling).
     */
    virtual void onTrackScrobbled(const Track& track, uint64_t timestamp) {
        (void)track;
        (void)timestamp;
    }

    /**
     * @brief Called when a new track is added to the library.
     */
    virtual void onTrackIndexed(const Track& track) {
        (void)track;
    }
};

} // namespace core
