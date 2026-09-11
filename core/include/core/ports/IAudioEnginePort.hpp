#pragma once

#include <string>
#include <cstdint>
#include <functional>

namespace core {

/**
 * @brief Current playback stream parameters.
 */
struct AudioStreamInfo {
    uint32_t sampleRate{44100};
    uint8_t bitDepth{16};
    uint8_t channels{2};
    uint32_t bitrate{0};
    std::string codec{"PCM"};
    bool isBitPerfect{true};
};

/**
 * @brief Audio engine port for low-latency, bit-perfect audio playback.
 */
class IAudioEnginePort {
public:
    virtual ~IAudioEnginePort() = default;

    virtual bool initialize(uint32_t sampleRate = 44100, uint8_t channels = 2) = 0;
    virtual bool load(const std::string& filePath) = 0;
    virtual bool play() = 0;
    virtual bool pause() = 0;
    virtual bool stop() = 0;
    virtual bool seek(uint64_t positionMs) = 0;
    virtual void setVolume(float volume) = 0; ///< 0.0f (mute) to 1.0f (max)
    virtual float getVolume() const = 0;
    virtual uint64_t getPositionMs() const = 0;
    virtual uint64_t getDurationMs() const = 0;
    virtual bool isPlaying() const = 0;
    virtual AudioStreamInfo getStreamInfo() const = 0;
    virtual void setEndOfTrackCallback(std::function<void()> callback) { (void)callback; }
};

} // namespace core
