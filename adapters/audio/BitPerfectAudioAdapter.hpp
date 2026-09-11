#pragma once

#include "core/ports/IAudioEnginePort.hpp"
#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <memory>
#include <mutex>
#include <functional>
#include <string>

namespace adapters {

/**
 * @brief Bit-perfect audio engine adapter powered by Qt 6 Multimedia & FFmpeg backend.
 */
class BitPerfectAudioAdapter : public QObject, public core::IAudioEnginePort {
    Q_OBJECT

public:
    explicit BitPerfectAudioAdapter(QObject* parent = nullptr);
    ~BitPerfectAudioAdapter() override;

    bool initialize(uint32_t sampleRate = 44100, uint8_t channels = 2) override;
    bool load(const std::string& filePath) override;
    bool play() override;
    bool pause() override;
    bool stop() override;
    bool seek(uint64_t positionMs) override;
    void setVolume(float volume) override;
    float getVolume() const override;
    uint64_t getPositionMs() const override;
    uint64_t getDurationMs() const override;
    bool isPlaying() const override;
    core::AudioStreamInfo getStreamInfo() const override;

    void setEndOfTrackCallback(std::function<void()> callback) override;

signals:
    void playbackFinished();

private:
    std::unique_ptr<QMediaPlayer> m_player;
    std::unique_ptr<QAudioOutput> m_audioOutput;
    core::AudioStreamInfo m_streamInfo;
    mutable std::mutex m_mutex;
    std::function<void()> m_endOfTrackCallback;
    std::string m_currentFilePath;
};

} // namespace adapters
