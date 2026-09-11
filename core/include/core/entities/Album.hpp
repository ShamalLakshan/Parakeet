#pragma once

#include <string>
#include <vector>
#include <cstdint>
#include <cstdio>
#include "Track.hpp"

namespace core {

/**
 * @brief Aggregated album info grouped from tracks.
 */
struct Album {
    std::string id;
    std::string title;
    std::string artist;
    uint32_t year{0};
    std::string genre;
    uint32_t trackCount{0};
    uint64_t totalDurationMs{0};
    std::string artHash;
    
    // Highest quality stats found across tracks in this album
    uint32_t maxSampleRate{44100};
    uint8_t maxBitDepth{16};
    std::string primaryCodec{"FLAC"};
    std::string qualityBadge{"Lossless"}; ///< "Hi-Res Lossless", "Lossless", "DSD", etc.

    /**
     * @brief Formats album total runtime (e.g. "45m 20s" or "1h 12m").
     */
    [[nodiscard]] std::string durationFormatted() const {
        const uint64_t totalSeconds = totalDurationMs / 1000;
        const uint64_t hours = totalSeconds / 3600;
        const uint64_t minutes = (totalSeconds % 3600) / 60;
        const uint64_t seconds = totalSeconds % 60;
        char buf[32];
        if (hours > 0) {
            std::snprintf(buf, sizeof(buf), "%lluh %02llum", (unsigned long long)hours, (unsigned long long)minutes);
        } else {
            std::snprintf(buf, sizeof(buf), "%llum %02llus", (unsigned long long)minutes, (unsigned long long)seconds);
        }
        return std::string(buf);
    }

    /**
     * @brief Formats audiophile summary line for UI cards.
     */
    [[nodiscard]] std::string audiophileSummary() const {
        std::string summary = primaryCodec;
        if (maxSampleRate >= 88200 || maxBitDepth >= 24) {
            summary += " • Hi-Res " + std::to_string(maxBitDepth) + "-bit/" + std::to_string(maxSampleRate / 1000) + "kHz";
        } else if (primaryCodec == "FLAC" || primaryCodec == "WAV" || primaryCodec == "ALAC") {
            summary += " • Lossless " + std::to_string(maxBitDepth) + "-bit/" + std::to_string(maxSampleRate / 1000) + "kHz";
        }
        return summary;
    }
};

} // namespace core
