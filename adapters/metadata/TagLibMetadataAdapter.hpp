#pragma once

#include "core/ports/IMetadataExtractor.hpp"
#include <memory>
#include <string>
#include <vector>

namespace adapters {

/**
 * @brief TagLib adapter for reading FLAC/WAV/MP3/M4A tags and embedded artwork.
 */
class TagLibMetadataAdapter : public core::IMetadataExtractor {
public:
  TagLibMetadataAdapter();
  ~TagLibMetadataAdapter() override = default;

  std::optional<core::Track> extract(const std::string &filePath) override;
  std::optional<core::ExtractedArtwork>
  extractArtwork(const std::string &filePath) override;
  bool supportsFormat(const std::string &extension) const override;
  std::string extractLyrics(const std::string &filePath) override;

private:
  std::string computeHash(const uint8_t *data, size_t size);
  std::string getFileExtension(const std::string &filePath) const;
};

} // namespace adapters
