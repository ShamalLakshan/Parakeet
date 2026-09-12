#pragma once

#include "core/ports/IAudioEnginePort.hpp"
#include <string>
#include <functional>

namespace tests {

class MockAudioEnginePort : public core::IAudioEnginePort {
public:
    bool initialize(uint32_t sampleRate = 44100, uint8_t channels = 2) override {
        m_sampleRate = sampleRate;
        m_channels = channels;
        return true;
    }

    bool load(const std::string& filePath) override {
        m_loadedFilePath = filePath;
        return true;
    }

    bool play() override {
        m_isPlaying = true;
        return true;
    }

    bool pause() override {
        m_isPlaying = false;
        return true;
    }

    bool stop() override {
        m_isPlaying = false;
        m_positionMs = 0;
        return true;
    }

    bool seek(uint64_t positionMs) override {
        m_positionMs = positionMs;
        return true;
    }

    void setVolume(float volume) override {
        m_volume = volume;
    }

    [[nodiscard]] float getVolume() const override {
        return m_volume;
    }

    [[nodiscard]] uint64_t getPositionMs() const override {
        return m_positionMs;
    }

    [[nodiscard]] uint64_t getDurationMs() const override {
        return m_durationMs;
    }

    [[nodiscard]] bool isPlaying() const override {
        return m_isPlaying;
    }

    [[nodiscard]] core::AudioStreamInfo getStreamInfo() const override {
        core::AudioStreamInfo info;
        info.sampleRate = m_sampleRate;
        info.channels = m_channels;
        info.codec = "PCM";
        return info;
    }

    void setEndOfTrackCallback(std::function<void()> callback) override {
        m_endOfTrackCallback = callback;
    }

    void triggerEndOfTrack() {
        if (m_endOfTrackCallback) {
            m_endOfTrackCallback();
        }
    }

    std::string m_loadedFilePath;
    uint32_t m_sampleRate{44100};
    uint8_t m_channels{2};
    uint64_t m_positionMs{0};
    uint64_t m_durationMs{180000};
    float m_volume{1.0f};
    bool m_isPlaying{false};
    std::function<void()> m_endOfTrackCallback;
};

} // namespace tests
