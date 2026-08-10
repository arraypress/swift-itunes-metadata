//
//  ITunesMetadata.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Search Apple's iTunes catalog and look up items by ID or app bundle ID —
/// podcasts, music, apps, movies, books, audiobooks, and TV — all **without an
/// API key**.
///
/// Backed by the public iTunes Search API (`https://itunes.apple.com`), which
/// needs no authentication. Results are heterogeneous — a single query can mix
/// songs, albums, apps, and podcasts — so every result is a unified
/// ``ITunesResult`` whose media-specific fields are optional.
///
/// The standout field is ``ITunesResult/feedURL``: for podcasts it is the RSS
/// feed URL, which pairs directly with `swift-podcast-metadata` to fetch the
/// full episode list.
///
/// ## Quick Start
///
/// ```swift
/// import ITunesMetadata
///
/// // Find a podcast and hand its RSS feed to swift-podcast-metadata
/// let podcasts = try await ITunesMetadata.search("syntax", media: .podcast, limit: 5)
/// if let show = podcasts.results.first {
///     print("\(show.name ?? "") — \(show.trackCount ?? 0) episodes")
///     if let feed = show.feedURL {
///         print("RSS feed: \(feed)")   // → PodcastMetadata.fetch(feed)
///     }
/// }
///
/// // Search music (albums)
/// let albums = try await ITunesMetadata.search(
///     "taylor swift", media: .music, entity: "album", limit: 10
/// )
/// for album in albums.results {
///     print("\(album.artistName ?? "") – \(album.name ?? "") (\(album.price ?? 0) \(album.currency ?? ""))")
/// }
///
/// // Look up an app by its bundle identifier
/// let app = try await ITunesMetadata.lookup(bundleId: "com.google.chrome.ios").first
/// print(app?.name ?? "not found")
/// ```
///
/// ## Media & Entity
///
/// Pass an ``ITunesMedia`` to `media:` to pick a catalog (`.podcast`, `.music`,
/// `.software`, `.movie`, `.ebook`, `.audiobook`, `.tvShow`, `.musicVideo`, or
/// `.all`). Narrow further with the optional `entity:` string — for example
/// `media: .music, entity: "song"` vs `entity: "album"`, or
/// `media: .movie, entity: "movieArtist"`. See Apple's Search API docs for the
/// full entity list per media type.
///
/// ## Rate Limits
///
/// The API allows roughly 20 requests per minute; over-limit responses surface
/// as ``ITunesMetadataError/rateLimited``.
public enum ITunesMetadata {

    // MARK: - Configuration

    /// Options for talking to the iTunes Search API.
    public struct Configuration: Sendable {

        /// The storefront country code (ISO alpha-2, e.g. `"US"`, `"GB"`).
        /// Determines pricing, availability, and localized names.
        public var country: String

        /// Creates a configuration.
        ///
        /// - Parameter country: The storefront country code. Defaults to `"US"`.
        public init(country: String = "US") {
            self.country = country
        }

        /// Reads `ITUNES_COUNTRY` from the environment, defaulting to `"US"`.
        public static var `default`: Configuration {
            Configuration(country: ProcessInfo.processInfo.environment["ITUNES_COUNTRY"] ?? "US")
        }
    }

    // MARK: - Search

    /// Searches the iTunes catalog.
    ///
    /// - Parameters:
    ///   - term: The free-text search term (URL-encoding is handled for you).
    ///   - media: The catalog to search. Defaults to ``ITunesMedia/all``.
    ///   - entity: An optional entity filter within the media type (e.g.
    ///     `"album"`, `"song"`, `"podcast"`, `"ebook"`). See Apple's docs.
    ///   - country: The storefront country code. Defaults to the value in
    ///     `configuration`.
    ///   - limit: The maximum number of results (`1...200`). Defaults to `25`.
    ///   - configuration: Storefront options. Defaults to ``Configuration/default``.
    /// - Returns: An ``ITunesSearchResults`` with the count and results.
    /// - Throws: ``ITunesMetadataError`` on invalid input, network, or API errors.
    public static func search(
        _ term: String,
        media: ITunesMedia = .all,
        entity: String? = nil,
        country: String? = nil,
        limit: Int = 25,
        configuration: Configuration = .default
    ) async throws -> ITunesSearchResults {
        guard !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ITunesMetadataError.invalidInput
        }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "media", value: media.rawValue),
            URLQueryItem(name: "country", value: country ?? configuration.country),
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 200)))
        ]
        if let entity, !entity.isEmpty {
            items.append(URLQueryItem(name: "entity", value: entity))
        }

        let data = try await ITunesClient.get(path: "/search", queryItems: items)
        return ITunesParser.searchResults(data)
    }

    // MARK: - Lookup

    /// Looks up items by their iTunes ID (track, collection, or artist ID).
    ///
    /// - Parameters:
    ///   - id: The iTunes identifier.
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options. Defaults to ``Configuration/default``.
    /// - Returns: The matching results (usually one; empty if nothing matched).
    public static func lookup(
        id: Int,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> [ITunesResult] {
        let items = [
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "country", value: country ?? configuration.country)
        ]
        let data = try await ITunesClient.get(path: "/lookup", queryItems: items)
        return ITunesParser.resultList(data)
    }

    /// Looks up an app by its bundle identifier (e.g. `"com.google.chrome.ios"`).
    ///
    /// - Parameters:
    ///   - bundleId: The app's bundle identifier.
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options. Defaults to ``Configuration/default``.
    /// - Returns: The matching results (usually one; empty if nothing matched).
    public static func lookup(
        bundleId: String,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> [ITunesResult] {
        guard !bundleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ITunesMetadataError.invalidInput
        }
        let items = [
            URLQueryItem(name: "bundleId", value: bundleId),
            URLQueryItem(name: "country", value: country ?? configuration.country)
        ]
        let data = try await ITunesClient.get(path: "/lookup", queryItems: items)
        return ITunesParser.resultList(data)
    }

    // MARK: - App Store reviews

    /// Fetches App Store customer reviews for an app.
    ///
    /// Backed by the keyless customer-reviews RSS feed. Apple paginates reviews
    /// (roughly 50 per page, up to ~10 pages).
    ///
    /// ```swift
    /// let app = try await ITunesMetadata.lookup(bundleId: "com.culturedcode.ThingsiPhone").first
    /// let reviews = try await ITunesMetadata.reviews(appID: app!.id)
    /// for r in reviews { print("★\(r.rating) \(r.title) — \(r.author ?? "")") }
    /// ```
    ///
    /// Reads the customer reviews Apple renders into an app's App Store page.
    ///
    /// ```swift
    /// let reviews = try await ITunesMetadata.reviews(appID: 389801252)
    /// for review in reviews {
    ///     print("\(review.rating)★ \(review.title) — \(review.author ?? "anonymous")")
    /// }
    /// ```
    ///
    /// ## What this can and cannot do
    ///
    /// **Ten reviews per storefront, and that is the ceiling.** The page ships
    /// one shelf of "most helpful" reviews. `offset`, `sort` and every page
    /// parameter Apple's own client sends are ignored when passed to the public
    /// URL — each returns the identical ten. The blob even names the next page
    /// (`/v1/catalog/us/apps/<id>/reviews?offset=10`, twenty per page), but that
    /// route is `amp-api.apps.apple.com`, which answers `401` without a token
    /// the browser is never given.
    ///
    /// **No sorting.** The shelf is fixed to most-helpful. Results are returned
    /// newest-first for determinism, but that orders ten helpful reviews — it
    /// does not reach the eleventh, more recent one.
    ///
    /// The one honest way to widen the net is storefronts: each returns its own
    /// ten, and they do not overlap. `us`, `gb`, `de`, `jp` and `au` share no
    /// review IDs. Roughly 175 storefronts puts the practical ceiling near
    /// 1,750 — skewed to whatever each locale found helpful, and mostly not in
    /// English.
    ///
    /// - Parameters:
    ///   - appID: The app's App Store ID (from ``ITunesResult/id`` or a lookup).
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options.
    /// - Returns: Up to ten reviews, newest first. Empty only when the app
    ///   genuinely has none.
    /// - Throws: ``ITunesMetadataError/parsingError(_:)`` when the page carries
    ///   no reviews section at all, which means Apple changed the page rather
    ///   than that the app is unreviewed.
    public static func reviews(
        appID: Int,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> [ITunesReview] {
        let cc = (country ?? configuration.country).lowercased()
        let json = try await AppStorePage.serializedData(
            appID: appID,
            country: cc,
            userAgent: ITunesClient.userAgent
        )

        // Distinguishing an unreviewed app from a broken extractor is the whole
        // reason this check exists. Both yield zero reviews; only one is a bug,
        // and the previous implementation reported the bug as an answer.
        guard AppStoreReviewParser.hasReviewSection(in: json) else {
            throw ITunesMetadataError.parsingError(
                "No reviews section on the App Store page for \(appID) in '\(cc)'"
            )
        }
        return AppStoreReviewParser.reviews(in: json)
    }

    // MARK: - Apps

    /// Looks up one app by its App Store ID.
    ///
    /// ```swift
    /// let app = try await ITunesMetadata.app(id: 904280696)
    /// print(app.name, app.version ?? "", app.formattedPrice ?? "")
    /// ```
    ///
    /// Returns ``AppStoreApp`` rather than ``ITunesResult`` because the shared
    /// model drops version, release notes and ratings — the fields worth
    /// looking an app up for.
    ///
    /// - Parameters:
    ///   - id: The App Store ID.
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options.
    /// - Throws: ``ITunesMetadataError/notFound`` when the storefront has no
    ///   such app. An app absent from one storefront may exist in another.
    public static func app(
        id: Int,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> AppStoreApp {
        let items = [
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "country", value: country ?? configuration.country)
        ]
        let data = try await ITunesClient.get(path: "/lookup", queryItems: items)
        guard let app = ITunesParser.appList(data).first else {
            throw ITunesMetadataError.notFound
        }
        return app
    }

    /// Looks up one app by its bundle identifier.
    ///
    /// - Parameters:
    ///   - bundleID: e.g. `"com.culturedcode.ThingsMac"`.
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options.
    /// - Throws: ``ITunesMetadataError/invalidInput`` when the identifier is
    ///   blank, ``ITunesMetadataError/notFound`` when the storefront has no
    ///   such app.
    public static func app(
        bundleID: String,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> AppStoreApp {
        guard !bundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ITunesMetadataError.invalidInput
        }
        let items = [
            URLQueryItem(name: "bundleId", value: bundleID),
            URLQueryItem(name: "country", value: country ?? configuration.country)
        ]
        let data = try await ITunesClient.get(path: "/lookup", queryItems: items)
        guard let app = ITunesParser.appList(data).first else {
            throw ITunesMetadataError.notFound
        }
        return app
    }

    /// Searches the App Store.
    ///
    /// A thin wrapper over ``search(_:media:entity:country:limit:configuration:)``
    /// that pins the media type and returns the app-shaped model.
    ///
    /// - Parameters:
    ///   - term: The search term.
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - limit: Maximum results (`1...200`). Defaults to `25`.
    ///   - macOnly: Restrict to Mac App Store listings.
    ///   - configuration: Storefront options.
    public static func apps(
        _ term: String,
        country: String? = nil,
        limit: Int = 25,
        macOnly: Bool = false,
        configuration: Configuration = .default
    ) async throws -> [AppStoreApp] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ITunesMetadataError.invalidInput }

        let items = [
            URLQueryItem(name: "term", value: trimmed),
            URLQueryItem(name: "media", value: ITunesMedia.software.rawValue),
            URLQueryItem(name: "entity", value: macOnly ? "macSoftware" : "software"),
            URLQueryItem(name: "country", value: country ?? configuration.country),
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 200)))
        ]
        let data = try await ITunesClient.get(path: "/search", queryItems: items)
        return ITunesParser.appList(data)
    }

    // MARK: - Charts

    /// Fetches an Apple top-charts feed (top apps, albums, songs, podcasts…).
    ///
    /// ```swift
    /// let topApps = try await ITunesMetadata.charts(.topFreeApps, limit: 25)
    /// for app in topApps { print("#\(app.rank) \(app.name) — \(app.artist ?? "")") }
    /// ```
    ///
    /// - Parameters:
    ///   - chart: Which chart to fetch.
    ///   - limit: The number of entries (`1...200`). Defaults to `50`.
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options.
    /// - Returns: The chart entries, ranked.
    public static func charts(
        _ chart: ITunesChart,
        limit: Int = 50,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> [ITunesChartEntry] {
        let cc = (country ?? configuration.country).lowercased()
        let path = "/\(cc)/rss/\(chart.rawValue)/limit=\(min(max(limit, 1), 200))/json"
        let data = try await ITunesClient.get(path: path, queryItems: [])
        return ITunesRSSParser.chartEntries(data)
    }
}
