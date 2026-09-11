#pragma once

#include "core/entities/Track.hpp"
#include "core/ports/IAudioEnginePort.hpp"
#include <vector>
#include <optional>
#include <memory>
#include <functional>

namespace core {

/**
 * @brief Playback states.
 */
enum class PlaybackState {
    Stopped,
    Playing,
    Paused
};

/**
 * @brief Core playback controller that manages queue, play/pause and connects to audio engine.
 */
class PlayerService {
public:
    explicit PlayerService(std::shared_ptr<IAudioEnginePort> audioEngine = nullptr);
    ~PlayerService() = default;

    /** @brief Sets or swaps the active audio engine port. */
    void setAudioEngine(std::shared_ptr<IAudioEnginePort> audioEngine);

    /** @brief Plays a single track directly. */
    void play(const Track& track);

    /** @brief Loads a playlist queue and starts playback at the given index. */
    void playQueue(const std::vector<Track>& tracks, size_t startIndex = 0);

    void pause();
    void resume();
    void togglePlayPause();
    void stop();
    void next();
    void previous();
    void seek(uint64_t positionMs);
    void setVolume(float volume);

    [[nodiscard]] PlaybackState getState() const { return m_state; }
    [[nodiscard]] bool isPlaying() const { return m_state == PlaybackState::Playing; }
    [[nodiscard]] std::optional<Track> getCurrentTrack() const { return m_currentTrack; }
    [[nodiscard]] uint64_t getPositionMs() const;
    [[nodiscard]] uint64_t getDurationMs() const;
    [[nodiscard]] float getVolume() const { return m_volume; }
    [[nodiscard]] const std::vector<Track>& getQueue() const { return m_queue; }
    [[nodiscard]] size_t getQueueIndex() const { return m_queueIndex; }

    void onTrackChanged(std::function<void(const Track&)> callback) { m_trackChangedCallback = callback; }
    void onStateChanged(std::function<void(PlaybackState)> callback) { m_stateChangedCallback = callback; }

private:
    std::shared_ptr<IAudioEnginePort> m_audioEngine;
    PlaybackState m_state{PlaybackState::Stopped};
    std::optional<Track> m_currentTrack;
    std::vector<Track> m_queue;
    size_t m_queueIndex{0};
    float m_volume{0.8f};

    std::function<void(const Track&)> m_trackChangedCallback;
    std::function<void(PlaybackState)> m_stateChangedCallback;
};

} // namespace core
