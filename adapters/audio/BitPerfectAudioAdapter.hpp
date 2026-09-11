#pragma once

#include "core/ports/IAudioEnginePort.hpp"
#include <atomic>
#include <chrono>
#include <mutex>
#include <string>

namespace adapters {

/**
 * @brief Bit-perfect audio engine adapter with precise stream tracking.
 */
class BitPerfectAudioAdapter : public core::IAudioEnginePort {
public:
  BitPerfectAudioAdapter();
  ~BitPerfectAudioAdapter() override;

  bool initialize(uint32_t sampleRate = 44100, uint8_t channels = 2) override;
  bool load(const std::string &filePath) override;
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

private:
  std::string m_currentFilePath;
  std::atomic<bool> m_isPlaying{false};
  std::atomic<bool> m_isPaused{false};
  std::atomic<float> m_volume{0.8f};
  std::atomic<uint64_t> m_positionMs{0};
  std::atomic<uint64_t> m_durationMs{0};

  core::AudioStreamInfo m_streamInfo;
  mutable std::mutex m_mutex;
  std::chrono::steady_clock::time_point m_lastPlayTime;
};

} // namespace adapters
