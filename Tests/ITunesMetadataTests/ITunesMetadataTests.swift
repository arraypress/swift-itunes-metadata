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

    // MARK: - Media coverage

    func testAllCasesOmitsTheRetiredMediaTypes() {
        // Verified against the live API in August 2026: film and TV return
        // zero results in every storefront, and a direct lookup of a known
        // film ID comes back empty. Offering them as choices would hand a
        // caller a guaranteed-empty answer that looks like a real one.
        let raws = ITunesMedia.allCases.map(\.rawValue)
        XCTAssertFalse(raws.contains("movie"))
        XCTAssertFalse(raws.contains("tvShow"))
    }

    func testAllCasesKeepsEveryServedMediaType() {
        let raws = Set(ITunesMedia.allCases.map(\.rawValue))
        XCTAssertEqual(raws, ["music", "podcast", "ebook", "software", "audiobook", "musicVideo", "all"])
    }

    // MARK: - App parsing

    func testParseApp() throws {
        let app = ITunesParser.app(try json(Fixture.appLookup))
        XCTAssertEqual(app.id, 904280696)
        XCTAssertEqual(app.bundleID, "com.culturedcode.ThingsMac")
        XCTAssertEqual(app.name, "Things 3")
        XCTAssertEqual(app.version, "3.22.13")
        XCTAssertEqual(app.seller, "Cultured Code GmbH & Co. KG")
        XCTAssertEqual(app.formattedPrice, "$49.99")
        XCTAssertEqual(app.price, 49.99)
        XCTAssertEqual(app.genres, ["Productivity", "Business"])
        XCTAssertEqual(app.minimumOSVersion, "10.15.0")
        XCTAssertEqual(app.contentRating, "4+")
        XCTAssertEqual(app.screenshotURLs.count, 2)
        XCTAssertNotNil(app.currentVersionDate)
        XCTAssertNotNil(app.releaseNotes)
    }

    func testFileSizeArrivesAsAStringAndIsParsed() throws {
        // Apple sends `fileSizeBytes` as a string; `as? Int` alone yields nil.
        XCTAssertEqual(ITunesParser.app(try json(Fixture.appLookup)).fileSizeBytes, 21_889_579)
    }

    func testRatingAcceptsBothIntAndDouble() throws {
        // An unrated app reports integer 0; a rated one reports a float.
        XCTAssertEqual(ITunesParser.app(try json(Fixture.appLookup)).rating, 0)
        let rating = try XCTUnwrap(ITunesParser.app(try json(Fixture.ratedApp)).rating)
        XCTAssertEqual(rating, 4.82, accuracy: 0.001)
        XCTAssertEqual(ITunesParser.app(try json(Fixture.ratedApp)).ratingCount, 27_792)
    }

    func testZeroRatingIsAValueNotAnAbsence() throws {
        // Mac App Store listings routinely report no ratings at all. Reporting
        // that as "unknown" would misrepresent a real answer.
        let app = ITunesParser.app(try json(Fixture.appLookup))
        XCTAssertEqual(app.ratingCount, 0)
        XCTAssertNotNil(app.rating)
    }

    func testMacAndFreeConveniences() throws {
        let paid = ITunesParser.app(try json(Fixture.appLookup))
        XCTAssertTrue(paid.isMac)
        XCTAssertFalse(paid.isFree)
        XCTAssertFalse(ITunesParser.app(try json(Fixture.ratedApp)).isMac)
        XCTAssertTrue(ITunesParser.app(try json(Fixture.ratedApp)).isFree)
    }

    func testAppListIgnoresNonSoftwareResults() throws {
        // A lookup can return the developer alongside the app.
        let envelope = """
            { "results": [ { "wrapperType": "artist", "artistName": "Cultured Code" },
                           \(Fixture.appLookup) ] }
            """
        XCTAssertEqual(ITunesParser.appList(try json(envelope)).count, 1)
    }

    // MARK: - Reviews & charts parsing

    func testParseReviewsFromPageBlob() throws {
        let blob = try jsonAny(Fixture.serializedPage)
        let reviews = AppStoreReviewParser.reviews(in: blob)

        XCTAssertEqual(reviews.count, 2, "the same review appears on several shelves and must be deduplicated")
        let newest = reviews[0]
        XCTAssertEqual(newest.id, 13539617732)
        XCTAssertEqual(newest.author, "JJLin283")
        XCTAssertEqual(newest.rating, 5)
        XCTAssertEqual(newest.title, "Questionable security")
        XCTAssertEqual(newest.body, "Someone hacked my account.")
        XCTAssertNotNil(newest.date)
        XCTAssertEqual(reviews[1].rating, 3, "results are newest first")
    }

    func testReviewIDsSurvivePastThirtyTwoBits() throws {
        // Real IDs run to eleven digits; an Int32 would silently wrap.
        let reviews = AppStoreReviewParser.reviews(in: try jsonAny(Fixture.serializedPage))
        XCTAssertGreaterThan(try XCTUnwrap(reviews.first).id, Int(Int32.max))
    }

    func testDuplicateShelvesDoNotInflateTheCount() throws {
        // The Instagram page carried 8 reviews and a naive walk reported 40.
        let blob = try jsonAny(Fixture.serializedPage)
        let ids = AppStoreReviewParser.reviews(in: blob).map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testNullPlaceholderAuthorBecomesNil() throws {
        // Apple renders the literal string "* null *" for absent values.
        let reviews = AppStoreReviewParser.reviews(in: try jsonAny(Fixture.serializedPage))
        XCTAssertNil(reviews[1].author)
    }

    func testReviewSectionDetection() throws {
        XCTAssertTrue(AppStoreReviewParser.hasReviewSection(in: try jsonAny(Fixture.serializedPage)))
        XCTAssertFalse(AppStoreReviewParser.hasReviewSection(in: try jsonAny(#"{"shelves":[]}"#)))
    }

    func testExtractsBlobFromPageHTML() {
        let html = """
            <html><head><title>App</title></head><body>
            <script type="application/json" id="serialized-server-data">[{"a":1}]</script>
            </body></html>
            """
        let json = AppStorePage.extractSerializedData(from: html)
        XCTAssertNotNil(json)
        XCTAssertEqual((json as? [[String: Any]])?.first?["a"] as? Int, 1)
    }

    func testMissingBlobIsReportedRatherThanTreatedAsEmpty() {
        // The retired RSS feed answered 200 with an empty envelope, which is
        // exactly how this used to fail silently.
        XCTAssertNil(AppStorePage.extractSerializedData(from: "<html><body>nothing</body></html>"))
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

    func testChartRawValues() {
        XCTAssertEqual(ITunesChart.topFreeApps.rawValue, "topfreeapplications")
        XCTAssertEqual(ITunesChart.topGrossingApps.rawValue, "topgrossingapplications")
    }

    func testLiveReviewsAndCharts() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["ITUNES_LIVE_TESTS"] == "1",
                          "Set ITUNES_LIVE_TESTS=1 to run live network tests.")
        // Instagram: large enough that an empty result means a broken source.
        let reviews = try await ITunesMetadata.reviews(appID: 389801252)
        XCTAssertFalse(reviews.isEmpty, "the page source has stopped yielding reviews")
        XCTAssertLessThanOrEqual(reviews.count, 10, "the public page ships one shelf of ten")
        XCTAssertTrue(reviews.allSatisfy { (1...5).contains($0.rating) })
        XCTAssertTrue(reviews.contains { !$0.body.isEmpty }, "review bodies must survive")

        // Storefronts do not overlap — the only way to widen the net.
        let gb = try await ITunesMetadata.reviews(appID: 389801252, country: "GB")
        XCTAssertTrue(Set(reviews.map(\.id)).isDisjoint(with: gb.map(\.id)))

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

    private func jsonAny(_ string: String) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(string.utf8), options: [.fragmentsAllowed])
    }

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

    /// A Mac App Store lookup result: paid, unrated, string file size.
    static let appLookup = """
    { "wrapperType": "software", "kind": "mac-software",
      "trackId": 904280696, "trackName": "Things 3",
      "bundleId": "com.culturedcode.ThingsMac",
      "sellerName": "Cultured Code GmbH & Co. KG",
      "sellerUrl": "https://culturedcode.com/things/",
      "artistViewUrl": "https://apps.apple.com/us/developer/cultured-code/id284971784",
      "trackViewUrl": "https://apps.apple.com/us/app/things-3/id904280696",
      "version": "3.22.13",
      "currentVersionReleaseDate": "2026-08-03T12:59:25Z",
      "releaseDate": "2017-05-18T16:42:04Z",
      "releaseNotes": "• Improved stability and bug fixes.",
      "averageUserRating": 0, "userRatingCount": 0,
      "price": 49.99, "formattedPrice": "$49.99", "currency": "USD",
      "primaryGenreName": "Productivity", "genres": ["Productivity", "Business"],
      "contentAdvisoryRating": "4+",
      "fileSizeBytes": "21889579",
      "minimumOsVersion": "10.15.0",
      "languageCodesISO2A": ["EN", "FR", "DE"],
      "description": "Get things done!",
      "artworkUrl512": "https://is1-ssl.mzstatic.com/512.png",
      "screenshotUrls": ["https://is1-ssl.mzstatic.com/a.png", "https://is1-ssl.mzstatic.com/b.png"] }
    """

    /// An iOS listing: free, rated, float average.
    static let ratedApp = """
    { "wrapperType": "software", "kind": "software",
      "trackId": 904237743, "trackName": "Things 3 for iPhone",
      "averageUserRating": 4.82, "userRatingCount": 27792,
      "price": 0, "formattedPrice": "Free", "currency": "USD",
      "genres": ["Productivity"] }
    """

    /// An App Store page blob, trimmed to shape: two distinct reviews, one of
    /// them repeated on a second shelf exactly as Apple's own page does.
    static let serializedPage = """
    [{
      "data": { "shelves": [
        { "$kind": "Shelf", "id": "allProductReviews", "contentType": "productReview", "items": [
            { "$kind": "Review", "id": "13539617732", "rating": 5,
              "title": "Questionable security", "reviewerName": "JJLin283",
              "date": "2025-12-21T18:38:52.000Z", "dateText": "* null *",
              "contents": "Someone hacked my account." },
            { "$kind": "Review", "id": "5289482643", "rating": 3,
              "title": "Some things to fix", "reviewerName": "* null *",
              "date": "2019-03-29T10:00:00.000Z",
              "contents": "Mostly good." } ] },
        { "$kind": "Shelf", "id": "userProductReviews", "contentType": "productReview", "items": [
            { "$kind": "Review", "id": "13539617732", "rating": 5,
              "title": "Questionable security", "reviewerName": "JJLin283",
              "date": "2025-12-21T18:38:52.000Z",
              "contents": "Someone hacked my account." } ] }
      ] }
    }]
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
