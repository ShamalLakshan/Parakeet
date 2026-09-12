#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

namespace core {

/**
 * @brief Plugin interface for audio visualizers (spectrum analyzers, meters).
 */
class IVisualizerPlugin {
public:
    virtual ~IVisualizerPlugin() = default;

    [[nodiscard]] virtual const char* getName() const noexcept = 0;
    [[nodiscard]] virtual const char* getVersion() const noexcept = 0;
    [[nodiscard]] virtual const char* getDescription() const noexcept = 0;

    virtual bool initialize() = 0;
    virtual void shutdown() = 0;

    /**
     * @brief Receive audio buffer for visualization.
     */
    virtual void processAudioBuffer(const float* buffer, size_t frames, uint32_t sampleRate, uint8_t channels) = 0;

    /**
     * @brief Get frequency spectrum bands normalized to [0.0f, 1.0f].
     * @param bandCount Number of frequency bands requested.
     */
    virtual std::vector<float> getFrequencyBands(size_t bandCount) const = 0;

    [[nodiscard]] virtual bool isEnabled() const noexcept = 0;
    virtual void setEnabled(bool enabled) = 0;
};

} // namespace core
