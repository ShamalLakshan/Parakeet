#include "core/services/PlayerService.hpp"
#include <iostream>

namespace core {

PlayerService::PlayerService(std::shared_ptr<IAudioEnginePort> audioEngine)
    : m_audioEngine(std::move(audioEngine)) {
}

void PlayerService::setAudioEngine(std::shared_ptr<IAudioEnginePort> audioEngine) {
    m_audioEngine = std::move(audioEngine);
}

void PlayerService::play(const Track& track) {
    m_currentTrack = track;
    m_state = PlaybackState::Playing;

    if (m_audioEngine) {
        m_audioEngine->load(track.filePath);
        m_audioEngine->play();
    }

    if (m_trackChangedCallback) {
        m_trackChangedCallback(track);
    }
    if (m_stateChangedCallback) {
        m_stateChangedCallback(m_state);
    }
}

void PlayerService::playQueue(const std::vector<Track>& tracks, size_t startIndex) {
    if (tracks.empty()) return;
    m_queue = tracks;
    m_queueIndex = (startIndex < tracks.size()) ? startIndex : 0;
    play(m_queue[m_queueIndex]);
}

void PlayerService::pause() {
    if (m_state == PlaybackState::Playing) {
        m_state = PlaybackState::Paused;
        if (m_audioEngine) {
            m_audioEngine->pause();
        }
        if (m_stateChangedCallback) {
            m_stateChangedCallback(m_state);
        }
    }
}

void PlayerService::resume() {
    if (m_state == PlaybackState::Paused) {
        m_state = PlaybackState::Playing;
        if (m_audioEngine) {
            m_audioEngine->play();
        }
        if (m_stateChangedCallback) {
            m_stateChangedCallback(m_state);
        }
    } else if (m_state == PlaybackState::Stopped && m_currentTrack.has_value()) {
        play(m_currentTrack.value());
    }
}

void PlayerService::togglePlayPause() {
    if (m_state == PlaybackState::Playing) {
        pause();
    } else {
        resume();
    }
}

void PlayerService::stop() {
    m_state = PlaybackState::Stopped;
    if (m_audioEngine) {
        m_audioEngine->stop();
    }
    if (m_stateChangedCallback) {
        m_stateChangedCallback(m_state);
    }
}

void PlayerService::next() {
    if (m_queue.empty()) return;
    m_queueIndex = (m_queueIndex + 1) % m_queue.size();
    play(m_queue[m_queueIndex]);
}

void PlayerService::previous() {
    if (m_queue.empty()) return;
    m_queueIndex = (m_queueIndex + m_queue.size() - 1) % m_queue.size();
    play(m_queue[m_queueIndex]);
}

void PlayerService::seek(uint64_t positionMs) {
    if (m_audioEngine) {
        m_audioEngine->seek(positionMs);
    }
}

void PlayerService::setVolume(float volume) {
    m_volume = std::clamp(volume, 0.0f, 1.0f);
    if (m_audioEngine) {
        m_audioEngine->setVolume(m_volume);
    }
}

uint64_t PlayerService::getPositionMs() const {
    if (m_audioEngine) {
        return m_audioEngine->getPositionMs();
    }
    return 0;
}

uint64_t PlayerService::getDurationMs() const {
    if (m_audioEngine) {
        return m_audioEngine->getDurationMs();
    }
    if (m_currentTrack.has_value()) {
        return m_currentTrack->durationMs;
    }
    return 0;
}

} // namespace core
