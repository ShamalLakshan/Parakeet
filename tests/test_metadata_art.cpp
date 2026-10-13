#include "adapters/metadata/TagLibMetadataAdapter.hpp"
#include "adapters/storage/SqliteDatabaseAdapter.hpp"
#include "adapters/ui_qt/models/TrackListModel.hpp"
#include <filesystem>
#include <fstream>
#include <gtest/gtest.h>

namespace fs = std::filesystem;

class MetadataArtTest : public ::testing::Test {
protected:
  fs::path m_testDir;

  void SetUp() override {
    m_testDir = fs::temp_directory_path() / "parakeet_test_art";
    fs::remove_all(m_testDir);
    fs::create_directories(m_testDir);
  }

  void TearDown() override { fs::remove_all(m_testDir); }

  void writeDummyFile(const fs::path &path, const std::vector<uint8_t> &data) {
    fs::create_directories(path.parent_path());
    std::ofstream ofs(path, std::ios::binary);
    ofs.write(reinterpret_cast<const char *>(data.data()), data.size());
  }
};

TEST_F(MetadataArtTest, DetectsCommonMimeTypesFromMagicBytes) {
  std::vector<uint8_t> jpegHeader = {0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10};
  EXPECT_EQ(adapters::TagLibMetadataAdapter::detectMimeType(jpegHeader.data(),
                                                            jpegHeader.size()),
            "image/jpeg");

  std::vector<uint8_t> pngHeader = {0x89, 0x50, 0x4E, 0x47,
                                    0x0D, 0x0A, 0x1A, 0x0A};
  EXPECT_EQ(adapters::TagLibMetadataAdapter::detectMimeType(pngHeader.data(),
                                                            pngHeader.size()),
            "image/png");

  std::vector<uint8_t> webpHeader = {'R', 'I', 'F', 'F', 0,   0,
                                     0,   0,   'W', 'E', 'B', 'P'};
  EXPECT_EQ(adapters::TagLibMetadataAdapter::detectMimeType(webpHeader.data(),
                                                            webpHeader.size()),
            "image/webp");

  std::vector<uint8_t> gifHeader = {'G', 'I', 'F', '8', '9', 'a'};
  EXPECT_EQ(adapters::TagLibMetadataAdapter::detectMimeType(gifHeader.data(),
                                                            gifHeader.size()),
            "image/gif");

  std::vector<uint8_t> bmpHeader = {'B', 'M', 0, 0};
  EXPECT_EQ(adapters::TagLibMetadataAdapter::detectMimeType(bmpHeader.data(),
                                                            bmpHeader.size()),
            "image/bmp");
}

TEST_F(MetadataArtTest, SupportsAllCommonAudioExtensionsCaseInsensitively) {
  adapters::TagLibMetadataAdapter adapter;
  EXPECT_TRUE(adapter.supportsFormat(".flac"));
  EXPECT_TRUE(adapter.supportsFormat(".FLAC"));
  EXPECT_TRUE(adapter.supportsFormat(".mp3"));
  EXPECT_TRUE(adapter.supportsFormat(".MP3"));
  EXPECT_TRUE(adapter.supportsFormat(".m4a"));
  EXPECT_TRUE(adapter.supportsFormat(".M4A"));
  EXPECT_TRUE(adapter.supportsFormat(".alac"));
  EXPECT_TRUE(adapter.supportsFormat(".wav"));
  EXPECT_TRUE(adapter.supportsFormat(".aiff"));
  EXPECT_TRUE(adapter.supportsFormat(".ogg"));
  EXPECT_TRUE(adapter.supportsFormat(".opus"));
  EXPECT_TRUE(adapter.supportsFormat(".dsf"));
  EXPECT_TRUE(adapter.supportsFormat(".dff"));
  EXPECT_TRUE(adapter.supportsFormat(".ape"));
  EXPECT_TRUE(adapter.supportsFormat(".wv"));
  EXPECT_TRUE(adapter.supportsFormat(".wma"));
  EXPECT_FALSE(adapter.supportsFormat(".txt"));
  EXPECT_FALSE(adapter.supportsFormat(".pdf"));
}

TEST_F(MetadataArtTest, DiscoversMixedCaseFolderArtwork) {
  adapters::TagLibMetadataAdapter adapter;
  fs::path albumDir = m_testDir / "Pink Floyd - Dark Side";
  fs::path dummyTrack = albumDir / "01 - Speak to Me.flac";
  fs::path coverFile = albumDir / "Cover.JPG";

  std::vector<uint8_t> jpegData = {0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10,
                                   'J',  'F',  'I',  'F',  0x00};
  writeDummyFile(dummyTrack, {0x66, 0x4C, 0x61, 0x43}); // "fLaC" dummy
  writeDummyFile(coverFile, jpegData);

  auto artOpt = adapter.extractArtwork(dummyTrack.string());
  ASSERT_TRUE(artOpt.has_value());
  EXPECT_EQ(artOpt->mimeType, "image/jpeg");
  EXPECT_FALSE(artOpt->artHash.empty());
  EXPECT_EQ(artOpt->data, jpegData);
}

TEST_F(MetadataArtTest, DiscoversArtworkFromParentOfDiscSubdirectory) {
  adapters::TagLibMetadataAdapter adapter;
  fs::path albumRoot = m_testDir / "The Wall";
  fs::path cd1Dir = albumRoot / "CD1";
  fs::path trackInCd1 = cd1Dir / "01 - In The Flesh.flac";
  fs::path rootCover = albumRoot / "folder.png";

  std::vector<uint8_t> pngData = {0x89, 0x50, 0x4E, 0x47, 0x0D,
                                  0x0A, 0x1A, 0x0A, 0x00};
  writeDummyFile(trackInCd1, {0x66, 0x4C, 0x61, 0x43});
  writeDummyFile(rootCover, pngData);

  auto artOpt = adapter.extractArtwork(trackInCd1.string());
  ASSERT_TRUE(artOpt.has_value());
  EXPECT_EQ(artOpt->mimeType, "image/png");
  EXPECT_EQ(artOpt->data, pngData);
}

TEST_F(MetadataArtTest, DatabaseResolvesTrackArtistWhenAlbumArtistMissing) {
  adapters::SqliteDatabaseAdapter db;
  std::string dbPath = (m_testDir / "test_music.db").string();
  ASSERT_TRUE(db.initialize(dbPath));

  core::Track t1;
  t1.id = "trk_1";
  t1.filePath = "/music/Radiohead/Kid A/01.flac";
  t1.title = "Everything in Its Right Place";
  t1.artist = "Radiohead";
  t1.album = "Kid A";
  t1.albumArtist = ""; // Missing album artist tag
  t1.genre = "Electronic";
  t1.year = 2000;
  t1.trackNumber = 1;
  t1.durationMs = 250000;
  t1.codec = "FLAC";

  ASSERT_TRUE(db.saveTrack(t1));

  auto albums = db.getAllAlbums();
  ASSERT_EQ(albums.size(), 1u);
  EXPECT_EQ(albums[0].title, "Kid A");
  EXPECT_EQ(albums[0].artist, "Radiohead");
}

TEST_F(MetadataArtTest, DatabaseResolvesLegacyUnknownArtistToTrackArtist) {
  adapters::SqliteDatabaseAdapter db;
  std::string dbPath = (m_testDir / "test_legacy.db").string();
  ASSERT_TRUE(db.initialize(dbPath));

  core::Track t1;
  t1.id = "trk_legacy";
  t1.filePath = "/music/Daft Punk/Discovery/01.flac";
  t1.title = "One More Time";
  t1.artist = "Daft Punk";
  t1.album = "Discovery";
  t1.albumArtist = "Unknown Artist"; // Legacy default before fix
  t1.durationMs = 320000;
  t1.codec = "FLAC";

  ASSERT_TRUE(db.saveTrack(t1));

  auto albums = db.getAllAlbums();
  ASSERT_EQ(albums.size(), 1u);
  EXPECT_EQ(albums[0].title, "Discovery");
  EXPECT_EQ(albums[0].artist, "Daft Punk");
}

TEST_F(MetadataArtTest, DatabaseResolvesCompilationWithAlbumArtist) {
  adapters::SqliteDatabaseAdapter db;
  std::string dbPath = (m_testDir / "test_comp.db").string();
  ASSERT_TRUE(db.initialize(dbPath));

  core::Track t1;
  t1.id = "trk_c1";
  t1.filePath = "/music/Comp/01.flac";
  t1.title = "Song A";
  t1.artist = "Artist One";
  t1.album = "Summer Hits";
  t1.albumArtist = "Various Artists";
  t1.durationMs = 180000;

  core::Track t2;
  t2.id = "trk_c2";
  t2.filePath = "/music/Comp/02.flac";
  t2.title = "Song B";
  t2.artist = "Artist Two";
  t2.album = "Summer Hits";
  t2.albumArtist = "Various Artists";
  t2.durationMs = 200000;

  ASSERT_TRUE(db.saveTrack(t1));
  ASSERT_TRUE(db.saveTrack(t2));

  auto albums = db.getAllAlbums();
  ASSERT_EQ(albums.size(), 1u);
  EXPECT_EQ(albums[0].title, "Summer Hits");
  EXPECT_EQ(albums[0].artist, "Various Artists");

  // Querying tracks for album by Various Artists returns all compilation tracks
  auto tracks = db.getTracksByAlbum("Summer Hits", "Various Artists");
  EXPECT_EQ(tracks.size(), 2u);
}

TEST_F(MetadataArtTest, TrackListModelResolvesArtistForAlbumArtistRole) {
  TrackListModel model;

  core::Track t1;
  t1.id = "t1";
  t1.title = "Track 1";
  t1.artist = "The Beatles";
  t1.album = "Abbey Road";
  t1.albumArtist = ""; // Empty

  core::Track t2;
  t2.id = "t2";
  t2.title = "Track 2";
  t2.artist = "The Beatles";
  t2.album = "Abbey Road";
  t2.albumArtist = "Unknown Artist"; // Legacy placeholder

  core::Track t3;
  t3.id = "t3";
  t3.title = "Track 3";
  t3.artist = "Featuring Artist";
  t3.album = "Solo Album";
  t3.albumArtist = "Primary Artist"; // Explicit album artist

  model.setTracks({t1, t2, t3});

  QModelIndex idx1 = model.index(0, 0);
  QModelIndex idx2 = model.index(1, 0);
  QModelIndex idx3 = model.index(2, 0);

  EXPECT_EQ(model.data(idx1, TrackListModel::AlbumArtistRole).toString(),
            "The Beatles");
  EXPECT_EQ(model.data(idx2, TrackListModel::AlbumArtistRole).toString(),
            "The Beatles");
  EXPECT_EQ(model.data(idx3, TrackListModel::AlbumArtistRole).toString(),
            "Primary Artist");
}

TEST_F(MetadataArtTest, AlbumGroupingMergesFeaturingArtistsWhenEnabled) {
  adapters::SqliteDatabaseAdapter db;
  std::string dbPath = (m_testDir / "test_grouping_enabled.db").string();
  ASSERT_TRUE(db.initialize(dbPath));

  core::Track t1;
  t1.id = "trk_dre_1";
  t1.filePath = "/music/2001/01.flac";
  t1.title = "The Watcher";
  t1.artist = "Dr. Dre";
  t1.album = "2001";
  t1.albumArtist = "";
  t1.durationMs = 200000;

  core::Track t2;
  t2.id = "trk_dre_2";
  t2.filePath = "/music/2001/02.flac";
  t2.title = "Still D.R.E.";
  t2.artist = "Dr. Dre feat. Snoop Dogg";
  t2.album = "2001";
  t2.albumArtist = "";
  t2.durationMs = 270000;

  core::Track t3;
  t3.id = "trk_dre_3";
  t3.filePath = "/music/2001/03.flac";
  t3.title = "Forgot About Dre";
  t3.artist = "Dr. Dre feat. Eminem";
  t3.album = "2001";
  t3.albumArtist = "";
  t3.durationMs = 220000;

  ASSERT_TRUE(db.saveTrack(t1));
  ASSERT_TRUE(db.saveTrack(t2));
  ASSERT_TRUE(db.saveTrack(t3));

  db.setGroupAlbumsByTitle(true);
  EXPECT_TRUE(db.groupAlbumsByTitle());

  auto albums = db.getAllAlbums();
  ASSERT_EQ(albums.size(), 1u);
  EXPECT_EQ(albums[0].title, "2001");
  EXPECT_EQ(albums[0].artist, "Dr. Dre");
  EXPECT_EQ(albums[0].trackCount, 3u);
  EXPECT_EQ(db.getAlbumCount(), 1u);

  auto tracks = db.getTracksByAlbum("2001", "Dr. Dre");
  EXPECT_EQ(tracks.size(), 3u);
}

TEST_F(MetadataArtTest, AlbumGroupingSplitsFeaturingArtistsWhenDisabled) {
  adapters::SqliteDatabaseAdapter db;
  std::string dbPath = (m_testDir / "test_grouping_disabled.db").string();
  ASSERT_TRUE(db.initialize(dbPath));

  core::Track t1;
  t1.id = "trk_dre_1";
  t1.filePath = "/music/2001/01.flac";
  t1.title = "The Watcher";
  t1.artist = "Dr. Dre";
  t1.album = "2001";
  t1.albumArtist = "";
  t1.durationMs = 200000;

  core::Track t2;
  t2.id = "trk_dre_2";
  t2.filePath = "/music/2001/02.flac";
  t2.title = "Still D.R.E.";
  t2.artist = "Dr. Dre feat. Snoop Dogg";
  t2.album = "2001";
  t2.albumArtist = "";
  t2.durationMs = 270000;

  core::Track t3;
  t3.id = "trk_dre_3";
  t3.filePath = "/music/2001/03.flac";
  t3.title = "Forgot About Dre";
  t3.artist = "Dr. Dre feat. Eminem";
  t3.album = "2001";
  t3.albumArtist = "";
  t3.durationMs = 220000;

  ASSERT_TRUE(db.saveTrack(t1));
  ASSERT_TRUE(db.saveTrack(t2));
  ASSERT_TRUE(db.saveTrack(t3));

  db.setGroupAlbumsByTitle(false);
  EXPECT_FALSE(db.groupAlbumsByTitle());

  auto albums = db.getAllAlbums();
  ASSERT_EQ(albums.size(), 3u);
  EXPECT_EQ(db.getAlbumCount(), 3u);

  auto tracksSolo = db.getTracksByAlbum("2001", "Dr. Dre");
  EXPECT_EQ(tracksSolo.size(), 1u);
  EXPECT_EQ(tracksSolo[0].title, "The Watcher");

  auto tracksSnoop = db.getTracksByAlbum("2001", "Dr. Dre feat. Snoop Dogg");
  EXPECT_EQ(tracksSnoop.size(), 1u);
  EXPECT_EQ(tracksSnoop[0].title, "Still D.R.E.");
}
