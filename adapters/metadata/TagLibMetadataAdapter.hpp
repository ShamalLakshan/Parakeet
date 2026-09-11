#pragma once

#include "core/ports/IMetadataExtractor.hpp"
#include <string>
#include <vector>
#include <memory>

namespace adapters {

/**
 * @brief TagLib adapter for reading FLAC/WAV/MP3/M4A tags and embedded artwork.
 */
class TagLibMetadataAdapter : public core::IMetadataExtractor {
public:
    TagLibMetadataAdapter();
    ~TagLibMetadataAdapter() override = default;

    std::optional<core::Track> extract(const std::string& filePath) override;
    std::optional<core::ExtractedArtwork> extractArtwork(const std::string& filePath) override;
    bool supportsFormat(const std::string& extension) const override;

private:
    std::string computeHash(const uint8_t* data, size_t size);
    std::string getFileExtension(const std::string& filePath) const;
};

} // namespace adapters
