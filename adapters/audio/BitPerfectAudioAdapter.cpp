#include "BitPerfectAudioAdapter.hpp"
#include <QUrl>
#include <algorithm>
#include <iostream>

namespace adapters {

BitPerfectAudioAdapter::BitPerfectAudioAdapter(QObject *parent)
    : QObject(parent), m_player(std::make_unique<QMediaPlayer>()),
      m_audioOutput(std::make_unique<QAudioOutput>()) {

  m_player->setAudioOutput(m_audioOutput.get());
  m_audioOutput->setVolume(0.8f);

  connect(m_player.get(), &QMediaPlayer::mediaStatusChanged, this,
          [this](QMediaPlayer::MediaStatus status) {
            if (status == QMediaPlayer::EndOfMedia) {
              emit playbackFinished();
              if (m_endOfTrackCallback) {
                m_endOfTrackCallback();
              }
            }
          });

  connect(m_player.get(), &QMediaPlayer::errorOccurred, this,
          [this](QMediaPlayer::Error error, const QString &errorString) {
            std::cerr << "BitPerfectAudioAdapter Error (" << error
                      << "): " << errorString.toStdString() << std::endl;
          });
}

BitPerfectAudioAdapter::~BitPerfectAudioAdapter() { stop(); }

bool BitPerfectAudioAdapter::initialize(uint32_t sampleRate, uint8_t channels) {
  std::lock_guard<std::mutex> lock(m_mutex);
  m_streamInfo.sampleRate = sampleRate;
  m_streamInfo.channels = channels;
  m_streamInfo.bitDepth = 24;
  m_streamInfo.isBitPerfect = true;
  m_streamInfo.codec = "FLAC/PCM";
  return true;
}

bool BitPerfectAudioAdapter::load(const std::string &filePath) {
  std::lock_guard<std::mutex> lock(m_mutex);
  m_currentFilePath = filePath;
  if (m_player) {
    m_player->setSource(QUrl::fromLocalFile(QString::fromStdString(filePath)));
  }
  return true;
}

bool BitPerfectAudioAdapter::play() {
  if (m_player) {
    m_player->play();
    return true;
  }
  return false;
}

bool BitPerfectAudioAdapter::pause() {
  if (m_player) {
    m_player->pause();
    return true;
  }
  return false;
}

bool BitPerfectAudioAdapter::stop() {
  if (m_player) {
    m_player->stop();
    return true;
  }
  return false;
}

bool BitPerfectAudioAdapter::seek(uint64_t positionMs) {
  if (m_player) {
    m_player->setPosition(static_cast<qint64>(positionMs));
    return true;
  }
  return false;
}

void BitPerfectAudioAdapter::setVolume(float volume) {
  if (m_audioOutput) {
    m_audioOutput->setVolume(std::clamp(volume, 0.0f, 1.0f));
  }
}

float BitPerfectAudioAdapter::getVolume() const {
  if (m_audioOutput) {
    return m_audioOutput->volume();
  }
  return 0.8f;
}

uint64_t BitPerfectAudioAdapter::getPositionMs() const {
  if (m_player) {
    return static_cast<uint64_t>(std::max<qint64>(0, m_player->position()));
  }
  return 0;
}

uint64_t BitPerfectAudioAdapter::getDurationMs() const {
  if (m_player) {
    return static_cast<uint64_t>(std::max<qint64>(0, m_player->duration()));
  }
  return 0;
}

bool BitPerfectAudioAdapter::isPlaying() const {
  return m_player && (m_player->playbackState() == QMediaPlayer::PlayingState);
}

core::AudioStreamInfo BitPerfectAudioAdapter::getStreamInfo() const {
  std::lock_guard<std::mutex> lock(m_mutex);
  return m_streamInfo;
}

void BitPerfectAudioAdapter::setEndOfTrackCallback(
    std::function<void()> callback) {
  m_endOfTrackCallback = std::move(callback);
}

void BitPerfectAudioAdapter::setPlaybackRate(float rate) {
  if (m_player) {
    m_player->setPlaybackRate(static_cast<qreal>(rate));
  }
}

float BitPerfectAudioAdapter::getPlaybackRate() const {
  if (m_player) {
    return static_cast<float>(m_player->playbackRate());
  }
  return 1.0f;
}

} // namespace adapters
