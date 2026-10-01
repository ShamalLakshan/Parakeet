#include "TagLibMetadataAdapter.hpp"

#include <taglib/attachedpictureframe.h>
#include <taglib/audioproperties.h>
#include <taglib/fileref.h>
#include <taglib/flacfile.h>
#include <taglib/flacpicture.h>
#include <taglib/id3v2tag.h>
#include <taglib/mp4coverart.h>
#include <taglib/mp4file.h>
#include <taglib/mp4tag.h>
#include <taglib/mpegfile.h>
#include <taglib/tag.h>
#include <taglib/tfile.h>
#include <taglib/wavfile.h>

#include <algorithm>
#include <chrono>
#include <filesystem>
#include <iomanip>
#include <sstream>

namespace fs = std::filesystem;

namespace adapters {

TagLibMetadataAdapter::TagLibMetadataAdapter() = default;

std::string
TagLibMetadataAdapter::getFileExtension(const std::string &filePath) const {
  fs::path p(filePath);
  std::string ext = p.extension().string();
  std::transform(ext.begin(), ext.end(), ext.begin(),
                 [](unsigned char c) { return std::tolower(c); });
  return ext;
}

bool TagLibMetadataAdapter::supportsFormat(const std::string &extension) const {
  std::string ext = extension;
  std::transform(ext.begin(), ext.end(), ext.begin(),
                 [](unsigned char c) { return std::tolower(c); });
  if (!ext.empty() && ext[0] != '.') {
    ext = "." + ext;
  }
  return (ext == ".flac" || ext == ".wav" || ext == ".aiff" || ext == ".aif" ||
          ext == ".mp3" || ext == ".m4a" || ext == ".alac" || ext == ".ogg" ||
          ext == ".opus" || ext == ".dsf" || ext == ".dff" || ext == ".aac" ||
          ext == ".wma");
}

std::string TagLibMetadataAdapter::computeHash(const uint8_t *data,
                                               size_t size) {
  // 64-bit FNV-1a hash for fast artwork deduplication
  uint64_t hash = 14695981039346656037ULL;
  for (size_t i = 0; i < size; ++i) {
    hash ^= data[i];
    hash *= 1099511628211ULL;
  }
  std::stringstream ss;
  ss << std::hex << std::setw(16) << std::setfill('0') << hash;
  return ss.str();
}

std::optional<core::Track>
TagLibMetadataAdapter::extract(const std::string &filePath) {
  if (!fs::exists(filePath)) {
    return std::nullopt;
  }

  core::Track track;
  track.filePath = filePath;
  fs::path p(filePath);

  // Default fallback from filename if tags are missing
  track.title = p.stem().string();
  track.artist = "Unknown Artist";
  track.album = "Unknown Album";
  track.albumArtist = "Unknown Artist";
  track.genre = "Unknown Genre";
  track.fileSizeBytes = fs::file_size(filePath);

  auto lastWriteTime = fs::last_write_time(filePath);
  auto sctp = std::chrono::time_point_cast<std::chrono::system_clock::duration>(
      lastWriteTime - fs::file_time_type::clock::now() +
      std::chrono::system_clock::now());
  track.dateAdded =
      std::chrono::duration_cast<std::chrono::seconds>(sctp.time_since_epoch())
          .count();

  std::string ext = getFileExtension(filePath);
  if (ext == ".flac") {
    track.codec = "FLAC";
  } else if (ext == ".wav") {
    track.codec = "WAV";
  } else if (ext == ".aiff" || ext == ".aif") {
    track.codec = "AIFF";
  } else if (ext == ".dsf" || ext == ".dff") {
    track.codec = "DSD";
  } else if (ext == ".mp3") {
    track.codec = "MP3";
  } else if (ext == ".m4a" || ext == ".alac") {
    track.codec = "ALAC";
  } else if (ext == ".opus") {
    track.codec = "OPUS";
  } else {
    track.codec = "PCM";
  }

  // Direct FLAC parsing for bit depth & pictures
  if (ext == ".flac") {
    TagLib::FLAC::File flacFile(filePath.c_str());
    if (flacFile.isValid()) {
      if (flacFile.tag()) {
        auto *tag = flacFile.tag();
        if (!tag->title().isEmpty())
          track.title = tag->title().to8Bit(true);
        if (!tag->artist().isEmpty())
          track.artist = tag->artist().to8Bit(true);
        if (!tag->album().isEmpty())
          track.album = tag->album().to8Bit(true);
        if (!tag->genre().isEmpty())
          track.genre = tag->genre().to8Bit(true);
        track.year = tag->year();
        track.trackNumber = tag->track();
      }
      if (flacFile.audioProperties()) {
        auto *props = flacFile.audioProperties();
        track.sampleRate = props->sampleRate();
        track.bitDepth = props->bitsPerSample();
        track.channels = props->channels();
        track.bitrate = props->bitrate();
        track.durationMs = props->lengthInMilliseconds();
      }
      const auto &pictures = flacFile.pictureList();
      if (!pictures.isEmpty()) {
        const auto *pic = pictures.front();
        track.artHash =
            computeHash(reinterpret_cast<const uint8_t *>(pic->data().data()),
                        pic->data().size());
      }

      track.id = "flac_" +
                 computeHash(reinterpret_cast<const uint8_t *>(filePath.data()),
                             filePath.size());
      return track;
    }
  }

  // Direct WAV / RIFF parsing
  if (ext == ".wav") {
    TagLib::RIFF::WAV::File wavFile(filePath.c_str());
    if (wavFile.isValid()) {
      if (wavFile.tag()) {
        auto *tag = wavFile.tag();
        if (!tag->title().isEmpty())
          track.title = tag->title().to8Bit(true);
        if (!tag->artist().isEmpty())
          track.artist = tag->artist().to8Bit(true);
        if (!tag->album().isEmpty())
          track.album = tag->album().to8Bit(true);
        if (!tag->genre().isEmpty())
          track.genre = tag->genre().to8Bit(true);
        track.year = tag->year();
        track.trackNumber = tag->track();
      }
      if (wavFile.audioProperties()) {
        auto *props = wavFile.audioProperties();
        track.sampleRate = props->sampleRate();
        track.bitDepth = props->bitsPerSample();
        track.channels = props->channels();
        track.bitrate = props->bitrate();
        track.durationMs = props->lengthInMilliseconds();
      }
      track.id = "wav_" +
                 computeHash(reinterpret_cast<const uint8_t *>(filePath.data()),
                             filePath.size());
      return track;
    }
  }

  // Generic FileRef fallback (MP3, M4A, OGG...)
  TagLib::FileRef fileRef(filePath.c_str());
  if (!fileRef.isNull() && fileRef.tag()) {
    auto *tag = fileRef.tag();
    if (!tag->title().isEmpty())
      track.title = tag->title().to8Bit(true);
    if (!tag->artist().isEmpty())
      track.artist = tag->artist().to8Bit(true);
    if (!tag->album().isEmpty())
      track.album = tag->album().to8Bit(true);
    if (!tag->genre().isEmpty())
      track.genre = tag->genre().to8Bit(true);
    track.year = tag->year();
    track.trackNumber = tag->track();

    if (fileRef.audioProperties()) {
      auto *props = fileRef.audioProperties();
      track.sampleRate = props->sampleRate();
      track.channels = props->channels();
      track.bitrate = props->bitrate();
      track.durationMs = props->lengthInMilliseconds();
      track.bitDepth = 16;
    }

    // Grab artwork from ID3v2 or MP4 container
    if (ext == ".mp3") {
      TagLib::MPEG::File mpegFile(filePath.c_str());
      if (mpegFile.isValid() && mpegFile.ID3v2Tag()) {
        auto *id3v2 = mpegFile.ID3v2Tag();
        const auto &frameList = id3v2->frameListMap()["APIC"];
        if (!frameList.isEmpty()) {
          auto *frame = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(
              frameList.front());
          if (frame) {
            track.artHash = computeHash(
                reinterpret_cast<const uint8_t *>(frame->picture().data()),
                frame->picture().size());
          }
        }
      }
    } else if (ext == ".m4a" || ext == ".alac") {
      TagLib::MP4::File mp4File(filePath.c_str());
      if (mp4File.isValid() && mp4File.tag()) {
        auto *mp4Tag = mp4File.tag();
        if (mp4Tag->itemMap().contains("covr")) {
          TagLib::MP4::CoverArtList coverList =
              mp4Tag->itemMap()["covr"].toCoverArtList();
          if (!coverList.isEmpty()) {
            const auto &cover = coverList.front();
            track.artHash = computeHash(
                reinterpret_cast<const uint8_t *>(cover.data().data()),
                cover.data().size());
          }
        }
      }
    }

    track.id = "audio_" +
               computeHash(reinterpret_cast<const uint8_t *>(filePath.data()),
                           filePath.size());
    return track;
  }

  return std::nullopt;
}

std::optional<core::ExtractedArtwork>
TagLibMetadataAdapter::extractArtwork(const std::string &filePath) {
  if (!fs::exists(filePath)) {
    return std::nullopt;
  }

  std::string ext = getFileExtension(filePath);

  // FLAC artwork
  if (ext == ".flac") {
    TagLib::FLAC::File flacFile(filePath.c_str());
    if (flacFile.isValid()) {
      const auto &pictures = flacFile.pictureList();
      if (!pictures.isEmpty()) {
        const auto *pic = pictures.front();
        core::ExtractedArtwork art;
        const char *dataPtr = pic->data().data();
        size_t dataSize = pic->data().size();
        art.data.assign(dataPtr, dataPtr + dataSize);
        art.mimeType = pic->mimeType().to8Bit(true);
        art.artHash = computeHash(art.data.data(), art.data.size());
        return art;
      }
    }
  }

  // MP3 ID3v2 APIC frame
  if (ext == ".mp3") {
    TagLib::MPEG::File mpegFile(filePath.c_str());
    if (mpegFile.isValid() && mpegFile.ID3v2Tag()) {
      auto *id3v2 = mpegFile.ID3v2Tag();
      const auto &frameList = id3v2->frameListMap()["APIC"];
      if (!frameList.isEmpty()) {
        auto *frame = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(
            frameList.front());
        if (frame) {
          core::ExtractedArtwork art;
          const char *dataPtr = frame->picture().data();
          size_t dataSize = frame->picture().size();
          art.data.assign(dataPtr, dataPtr + dataSize);
          art.mimeType = frame->mimeType().to8Bit(true);
          art.artHash = computeHash(art.data.data(), art.data.size());
          return art;
        }
      }
    }
  }

  // MP4 / M4A / ALAC artwork atom
  if (ext == ".m4a" || ext == ".alac" || ext == ".mp4") {
    TagLib::MP4::File mp4File(filePath.c_str());
    if (mp4File.isValid() && mp4File.tag()) {
      auto *mp4Tag = mp4File.tag();
      if (mp4Tag->itemMap().contains("covr")) {
        TagLib::MP4::CoverArtList coverList =
            mp4Tag->itemMap()["covr"].toCoverArtList();
        if (!coverList.isEmpty()) {
          const auto &cover = coverList.front();
          core::ExtractedArtwork art;
          const char *dataPtr = cover.data().data();
          size_t dataSize = cover.data().size();
          art.data.assign(dataPtr, dataPtr + dataSize);
          art.mimeType = (cover.format() == TagLib::MP4::CoverArt::PNG)
                             ? "image/png"
                             : "image/jpeg";
          art.artHash = computeHash(art.data.data(), art.data.size());
          return art;
        }
      }
    }
  }

  // Fallback: check folder for cover.jpg, folder.png, etc.
  fs::path dir = fs::path(filePath).parent_path();
  std::vector<std::string> artFilenames = {"cover.jpg",  "cover.png",
                                           "folder.jpg", "folder.png",
                                           "front.jpg",  "front.png"};
  for (const auto &fname : artFilenames) {
    fs::path artPath = dir / fname;
    if (fs::exists(artPath) && fs::is_regular_file(artPath)) {
      core::ExtractedArtwork art;
      size_t size = fs::file_size(artPath);
      art.data.resize(size);
      FILE *f = fopen(artPath.string().c_str(), "rb");
      if (f) {
        size_t readBytes = fread(art.data.data(), 1, size, f);
        fclose(f);
        if (readBytes == size) {
          art.mimeType =
              (artPath.extension() == ".png") ? "image/png" : "image/jpeg";
          art.artHash = computeHash(art.data.data(), art.data.size());
          return art;
        }
      }
    }
  }

  return std::nullopt;
}

} // namespace adapters
