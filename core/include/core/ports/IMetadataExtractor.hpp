#pragma once

#include <string>
#include <vector>
#include <optional>
#include <cstdint>
#include "core/entities/Track.hpp"

namespace core {

/**
 * @brief Raw embedded album art binary buffer.
 */
struct ExtractedArtwork {
    std::vector<uint8_t> data;
    std::string mimeType{"image/jpeg"};
    std::string artHash;
};

/**
 * @brief Tag reader interface for extracting track metadata and cover art.
 */
class IMetadataExtractor {
public:
    virtual ~IMetadataExtractor() = default;

    /** @brief Reads audio tags and stream properties from a file. */
    virtual std::optional<Track> extract(const std::string& filePath) = 0;

    /** @brief Extracts embedded cover art from a file if present. */
    virtual std::optional<ExtractedArtwork> extractArtwork(const std::string& filePath) = 0;

    /** @brief Checks if a file extension (e.g. ".flac", ".wav") is supported. */
    virtual bool supportsFormat(const std::string& extension) const = 0;
};

} // namespace core
