#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include "core/entities/Track.hpp"

namespace core {

enum class PlaybackState;

/**
 * @brief Plugin interface for playback events and DSP hooks.
 */
class IPlayerPlugin {
public:
    virtual ~IPlayerPlugin() = default;

    [[nodiscard]] virtual const char* getName() const noexcept = 0;
    [[nodiscard]] virtual const char* getVersion() const noexcept = 0;
    [[nodiscard]] virtual const char* getDescription() const noexcept = 0;

    virtual bool initialize() = 0;
    virtual void shutdown() = 0;

    /**
     * @brief Audio buffer callback before DSP processing.
     */
    virtual void onPreDsp(float* buffer, size_t frames, uint32_t sampleRate, uint8_t channels) {
        (void)buffer; (void)frames; (void)sampleRate; (void)channels;
    }

    /**
     * @brief Audio buffer callback after DSP processing.
     */
    virtual void onPostDsp(float* buffer, size_t frames, uint32_t sampleRate, uint8_t channels) {
        (void)buffer; (void)frames; (void)sampleRate; (void)channels;
    }

    /**
     * @brief Called when a new track starts playing.
     */
    virtual void onTrackStarted(const Track& track) {
        (void)track;
    }

    /**
     * @brief Called when playback state changes.
     */
    virtual void onPlaybackStateChanged(PlaybackState state) {
        (void)state;
    }
};

} // namespace core
