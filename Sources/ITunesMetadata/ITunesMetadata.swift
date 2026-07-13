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
    /// - Parameters:
    ///   - appID: The app's iTunes ID (from ``ITunesResult/id`` or a lookup).
    ///   - sortBy: Review ordering. Defaults to ``ITunesReviewSort/mostRecent``.
    ///   - page: The 1-based page number (`1...10`).
    ///   - country: The storefront country code. Defaults to `configuration`.
    ///   - configuration: Storefront options.
    /// - Returns: The reviews on that page.
    public static func reviews(
        appID: Int,
        sortBy: ITunesReviewSort = .mostRecent,
        page: Int = 1,
        country: String? = nil,
        configuration: Configuration = .default
    ) async throws -> [ITunesReview] {
        let cc = (country ?? configuration.country).lowercased()
        // Note: the feed uses lowercase `sortby`, and `page=` must precede `id=`.
        let path = "/\(cc)/rss/customerreviews/page=\(max(page, 1))/id=\(appID)/sortby=\(sortBy.rawValue)/json"
        let data = try await ITunesClient.get(path: path, queryItems: [])
        return ITunesRSSParser.reviews(data)
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
