//
//  ITunesMetadataTests.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import ITunesMetadata

final class ITunesMetadataTests: XCTestCase {

    // MARK: - Media raw values

    func testMediaRawValuesMatchAPI() {
        XCTAssertEqual(ITunesMedia.music.rawValue, "music")
        XCTAssertEqual(ITunesMedia.podcast.rawValue, "podcast")
        XCTAssertEqual(ITunesMedia.movie.rawValue, "movie")
        XCTAssertEqual(ITunesMedia.ebook.rawValue, "ebook")
        XCTAssertEqual(ITunesMedia.software.rawValue, "software")
        XCTAssertEqual(ITunesMedia.audiobook.rawValue, "audiobook")
        XCTAssertEqual(ITunesMedia.tvShow.rawValue, "tvShow")
        XCTAssertEqual(ITunesMedia.musicVideo.rawValue, "musicVideo")
        XCTAssertEqual(ITunesMedia.all.rawValue, "all")
    }

    // MARK: - Podcast parsing

    func testParsePodcastSearch() throws {
        let results = ITunesParser.searchResults(try json(Fixture.podcastSearch))
        XCTAssertEqual(results.resultCount, 1)
        XCTAssertEqual(results.results.count, 1)

        let show = try XCTUnwrap(results.results.first)
        XCTAssertEqual(show.id, 1253186678)
        XCTAssertEqual(show.wrapperType, "track")
        XCTAssertEqual(show.kind, "podcast")
        XCTAssertTrue(show.isPodcast)
        XCTAssertEqual(show.name, "Syntax - Tasty Web Development Treats")
        XCTAssertEqual(show.collectionName, "Syntax - Tasty Web Development Treats")
        XCTAssertEqual(show.feedURL, "https://feeds.megaphone.fm/FSI1483080183")
        XCTAssertEqual(show.genre, "Technology")
        XCTAssertEqual(show.trackCount, 1019)
        XCTAssertEqual(show.country, "USA")
        XCTAssertEqual(show.artworkURL, "https://example.com/100x100bb.jpg")
        XCTAssertNotNil(show.releaseDate)
        XCTAssertNil(show.previewURL)
    }

    // MARK: - Music parsing

    func testParseMusicAlbumSearch() throws {
        let results = ITunesParser.searchResults(try json(Fixture.albumSearch))
        XCTAssertEqual(results.resultCount, 1)

        let album = try XCTUnwrap(results.results.first)
        // Albums have no trackId — id falls back to collectionId.
        XCTAssertEqual(album.id, 1440935467)
        XCTAssertEqual(album.wrapperType, "collection")
        XCTAssertNil(album.kind)
        XCTAssertFalse(album.isPodcast)
        // No trackName — name falls back to collectionName.
        XCTAssertEqual(album.name, "1989")
        XCTAssertEqual(album.artistName, "Taylor Swift")
        XCTAssertEqual(album.price, 10.99)
        XCTAssertEqual(album.currency, "USD")
        XCTAssertEqual(album.genre, "Pop")
        XCTAssertNil(album.feedURL)
    }

    func testParseSongResult() throws {
        let song = ITunesParser.result(try json(Fixture.song))
        XCTAssertEqual(song.id, 1440935808)               // trackId wins over collectionId
        XCTAssertEqual(song.kind, "song")
        XCTAssertEqual(song.name, "Blank Space")
        XCTAssertEqual(song.collectionName, "1989")
        XCTAssertEqual(song.price, 1.29)                  // trackPrice wins over collectionPrice
        XCTAssertEqual(song.durationMillis, 231833)
        XCTAssertEqual(song.previewURL, "https://example.com/preview.m4a")
    }

    // MARK: - Software parsing

    func testParseSoftwareResult() throws {
        let app = ITunesParser.result(try json(Fixture.software))
        XCTAssertEqual(app.id, 1232780281)
        XCTAssertEqual(app.wrapperType, "software")
        XCTAssertEqual(app.kind, "software")
        XCTAssertEqual(app.name, "Notion: Notes, Tasks, AI")
        XCTAssertEqual(app.artistName, "Notion Labs, Incorporated")
        XCTAssertEqual(app.price, 0.0)
        XCTAssertEqual(app.genre, "Productivity")
        XCTAssertNotNil(app.description)
        XCTAssertTrue(app.description?.contains("workspace") == true)
        // Apps carry no country / collection / preview fields.
        XCTAssertNil(app.country)
        XCTAssertNil(app.collectionName)
        XCTAssertNil(app.previewURL)
    }

    // MARK: - Lookup parsing

    func testParseLookupList() throws {
        let results = ITunesParser.resultList(try json(Fixture.podcastSearch))
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, 1253186678)
    }

    // MARK: - Input validation

    func testEmptySearchTermThrowsInvalidInput() async {
        do {
            _ = try await ITunesMetadata.search("   ", media: .podcast)
            XCTFail("Expected invalidInput")
        } catch ITunesMetadataError.invalidInput {
            // expected
        } catch {
            XCTFail("Expected invalidInput, got \(error)")
        }
    }

    // MARK: - Live tests (opt-in)

    /// Keyless live verification. Gated on network via `ITUNES_LIVE_TESTS=1`.
    func testLiveSearchAndLookup() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ITUNES_LIVE_TESTS"] == "1",
                          "Set ITUNES_LIVE_TESTS=1 to run live network tests.")

        // Podcast search — must surface an RSS feed URL.
        let podcasts = try await ITunesMetadata.search("syntax", media: .podcast, limit: 5)
        XCTAssertGreaterThan(podcasts.resultCount, 0)
        let show = try XCTUnwrap(podcasts.results.first { $0.feedURL != nil })
        XCTAssertTrue(show.isPodcast)
        XCTAssertNotNil(show.feedURL)

        // Music search.
        let albums = try await ITunesMetadata.search("taylor swift", media: .music, entity: "album", limit: 3)
        XCTAssertGreaterThan(albums.resultCount, 0)
        XCTAssertFalse(albums.results.isEmpty)

        // Lookup by ID (Syntax podcast).
        let looked = try await ITunesMetadata.lookup(id: 1253186678)
        XCTAssertEqual(looked.first?.id, 1253186678)

        if ProcessInfo.processInfo.environment["ITUNES_PRINT"] == "1" {
            print("=== podcast ===")
            print("• \(show.name ?? "") — \(show.trackCount ?? 0) episodes")
            print("  feed: \(show.feedURL ?? "?")")
            print("=== music ===")
            for a in albums.results.prefix(3) {
                print("• \(a.artistName ?? "") – \(a.name ?? "") (\(a.price ?? 0) \(a.currency ?? ""))")
            }
        }
    }

    // MARK: - Reviews & charts parsing

    func testParseReviews() throws {
        let reviews = ITunesRSSParser.reviews(try json(Fixture.reviewsRSS))
        XCTAssertEqual(reviews.count, 2)
        let r = reviews[0]
        XCTAssertEqual(r.id, 14279148279)
        XCTAssertEqual(r.author, "EvienneK.SEA")
        XCTAssertEqual(r.rating, 5)
        XCTAssertEqual(r.title, "The ADHD Tamer")
        XCTAssertEqual(r.body, "This app reshaped my life.")
        XCTAssertEqual(r.version, "3.22.9")
        XCTAssertNotNil(r.updated)
        XCTAssertEqual(reviews[1].rating, 2)
    }

    func testParseCharts() throws {
        let entries = ITunesRSSParser.chartEntries(try json(Fixture.chartsRSS))
        XCTAssertEqual(entries.count, 2)
        let top = entries[0]
        XCTAssertEqual(top.rank, 1)
        XCTAssertEqual(top.id, 530168168)
        XCTAssertEqual(top.bundleID, "com.cbsvideo.app")
        XCTAssertEqual(top.name, "Paramount+")
        XCTAssertEqual(top.artist, "CBS Interactive")
        XCTAssertEqual(top.price, 0.0)
        XCTAssertEqual(top.currency, "USD")
        XCTAssertEqual(top.category, "Entertainment")
        XCTAssertEqual(top.artworkURL, "https://is1-ssl.mzstatic.com/big.png")
        XCTAssertEqual(entries[1].rank, 2)
    }

    func testChartAndSortRawValues() {
        XCTAssertEqual(ITunesChart.topFreeApps.rawValue, "topfreeapplications")
        XCTAssertEqual(ITunesReviewSort.mostRecent.rawValue, "mostRecent")
    }

    func testLiveReviewsAndCharts() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ITUNES_LIVE_TESTS"] == "1",
                          "Set ITUNES_LIVE_TESTS=1 to run live network tests.")
        // Things 3 reviews.
        let reviews = try await ITunesMetadata.reviews(appID: 904237743, page: 1)
        XCTAssertFalse(reviews.isEmpty)
        XCTAssertTrue(reviews.allSatisfy { (1...5).contains($0.rating) })

        let topApps = try await ITunesMetadata.charts(.topFreeApps, limit: 5)
        XCTAssertFalse(topApps.isEmpty)
        XCTAssertEqual(topApps.first?.rank, 1)

        if ProcessInfo.processInfo.environment["ITUNES_PRINT"] == "1" {
            print("=== Things 3 reviews ===")
            for r in reviews.prefix(3) { print("★\(r.rating) \(r.title) — \(r.author ?? "")") }
            print("=== top free apps ===")
            for a in topApps { print("#\(a.rank) \(a.name) — \(a.artist ?? "")") }
        }
    }

    // MARK: - Helpers

    private func json(_ string: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(string.utf8)) as? [String: Any])
    }
}

// MARK: - Fixtures (mirror verified iTunes Search API shapes)

private enum Fixture {

    /// A podcast search envelope (`wrapperType: track`, `kind: podcast`, `feedUrl`).
    static let podcastSearch = """
    { "resultCount": 1, "results": [
      { "wrapperType": "track", "kind": "podcast",
        "collectionId": 1253186678, "trackId": 1253186678,
        "artistName": "Wes Bos & Scott Tolinski",
        "collectionName": "Syntax - Tasty Web Development Treats",
        "trackName": "Syntax - Tasty Web Development Treats",
        "collectionViewUrl": "https://podcasts.apple.com/us/podcast/id1253186678",
        "feedUrl": "https://feeds.megaphone.fm/FSI1483080183",
        "trackViewUrl": "https://podcasts.apple.com/us/podcast/id1253186678",
        "artworkUrl60": "https://example.com/60x60bb.jpg",
        "artworkUrl100": "https://example.com/100x100bb.jpg",
        "collectionPrice": 0.0, "trackPrice": 0.0,
        "releaseDate": "2026-07-08T11:00:00Z",
        "trackCount": 1019, "trackTimeMillis": 2360,
        "country": "USA", "currency": "USD", "primaryGenreName": "Technology" }
    ] }
    """

    /// A music album search envelope (`wrapperType: collection`, no `trackId`/`kind`).
    static let albumSearch = """
    { "resultCount": 1, "results": [
      { "wrapperType": "collection", "collectionType": "Album",
        "artistId": 159260351, "collectionId": 1440935467,
        "artistName": "Taylor Swift", "collectionName": "1989",
        "collectionViewUrl": "https://music.apple.com/us/album/1989/1440935467",
        "artworkUrl60": "https://example.com/60x60bb.jpg",
        "artworkUrl100": "https://example.com/100x100bb.jpg",
        "collectionPrice": 10.99, "trackCount": 13,
        "country": "USA", "currency": "USD",
        "releaseDate": "2014-10-27T07:00:00Z", "primaryGenreName": "Pop" }
    ] }
    """

    /// A single music track (`wrapperType: track`, `kind: song`, `previewUrl`).
    static let song = """
    { "wrapperType": "track", "kind": "song",
      "artistId": 159260351, "collectionId": 1440935467, "trackId": 1440935808,
      "artistName": "Taylor Swift", "collectionName": "1989", "trackName": "Blank Space",
      "trackViewUrl": "https://music.apple.com/us/album/1440935467?i=1440935808",
      "previewUrl": "https://example.com/preview.m4a",
      "artworkUrl100": "https://example.com/100x100bb.jpg",
      "collectionPrice": 10.99, "trackPrice": 1.29,
      "releaseDate": "2014-10-27T07:00:00Z", "trackCount": 13, "trackTimeMillis": 231833,
      "country": "USA", "currency": "USD", "primaryGenreName": "Pop" }
    """

    /// A single app (`wrapperType: software`, `description`, no `country`/`collectionName`).
    static let software = """
    { "wrapperType": "software", "kind": "software",
      "trackId": 1232780281, "trackName": "Notion: Notes, Tasks, AI",
      "artistId": 1232780280, "artistName": "Notion Labs, Incorporated",
      "bundleId": "notion.id",
      "trackViewUrl": "https://apps.apple.com/us/app/id1232780281",
      "artworkUrl60": "https://example.com/60x60bb.jpg",
      "artworkUrl100": "https://example.com/100x100bb.jpg",
      "price": 0.0, "currency": "USD", "primaryGenreName": "Productivity",
      "releaseDate": "2017-09-14T19:07:31Z",
      "description": "Notion is an AI-powered all-in-one workspace." }
    """

    /// A customer-reviews RSS envelope (values wrapped as `{ "label": … }`).
    static let reviewsRSS = """
    { "feed": { "entry": [
        { "id": { "label": "14279148279" },
          "author": { "name": { "label": "EvienneK.SEA" } },
          "im:rating": { "label": "5" }, "im:version": { "label": "3.22.9" },
          "im:voteCount": { "label": "0" }, "im:voteSum": { "label": "0" },
          "title": { "label": "The ADHD Tamer" },
          "content": { "label": "This app reshaped my life.", "attributes": { "type": "text" } },
          "updated": { "label": "2026-07-08T12:10:07-07:00" } },
        { "id": { "label": "14279000000" },
          "author": { "name": { "label": "someone" } },
          "im:rating": { "label": "2" }, "title": { "label": "Meh" },
          "content": { "label": "Too pricey." }, "updated": { "label": "2026-07-01T00:00:00-07:00" } }
    ] } }
    """

    /// A top-charts RSS envelope (attributes under `{ "attributes": … }`).
    static let chartsRSS = """
    { "feed": { "entry": [
        { "im:name": { "label": "Paramount+" }, "im:artist": { "label": "CBS Interactive" },
          "im:price": { "label": "Get", "attributes": { "amount": "0.00", "currency": "USD" } },
          "category": { "attributes": { "label": "Entertainment", "term": "Entertainment" } },
          "im:image": [ { "label": "https://is1-ssl.mzstatic.com/small.png" },
                        { "label": "https://is1-ssl.mzstatic.com/big.png" } ],
          "id": { "label": "https://apps.apple.com/us/app/paramount/id530168168",
                  "attributes": { "im:id": "530168168", "im:bundleId": "com.cbsvideo.app" } },
          "im:releaseDate": { "label": "2013-03-14T00:41:45-07:00" } },
        { "im:name": { "label": "Netflix" }, "im:artist": { "label": "Netflix, Inc." },
          "im:price": { "attributes": { "amount": "0.00", "currency": "USD" } },
          "id": { "attributes": { "im:id": "363590051", "im:bundleId": "com.netflix.Netflix" } } }
    ] } }
    """
}
