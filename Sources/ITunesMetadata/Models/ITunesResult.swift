//
//  ITunesResult.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single result from an iTunes search or lookup.
///
/// The iTunes Search API returns a heterogeneous list — a query can mix
/// podcasts, songs, albums, apps, books, movies, and TV shows, each exposing a
/// slightly different set of fields. This model unifies the fields common to
/// every media type and makes the media-specific ones optional.
///
/// The most useful media-specific field is ``feedURL``: for podcasts it is the
/// RSS feed URL, which pairs directly with `swift-podcast-metadata` to fetch the
/// full episode list.
public struct ITunesResult: Sendable, Identifiable {

    // MARK: - Common fields

    /// The item's identifier (`trackId`, falling back to `collectionId`).
    public let id: Int

    /// The kind of container, e.g. `"track"`, `"collection"`, or `"software"`.
    /// Absent for some media types (books).
    public let wrapperType: String?

    /// The specific kind, e.g. `"podcast"`, `"song"`, `"feature-movie"`,
    /// `"software"`, `"ebook"`. Absent for album collections.
    public let kind: String?

    /// The primary display name (`trackName`, falling back to `collectionName`).
    public let name: String?

    /// The artist / author / developer name.
    public let artistName: String?

    /// The collection (album / show / season) name, when applicable.
    public let collectionName: String?

    /// The best available artwork URL (`artworkUrl100`, falling back to `artworkUrl60`).
    public let artworkURL: String?

    /// A link to view the item in iTunes / Apple's storefront
    /// (`trackViewUrl`, falling back to `collectionViewUrl`).
    public let viewURL: String?

    /// The release date, parsed from the API's ISO-8601 timestamp.
    public let releaseDate: Date?

    /// The primary genre name, e.g. `"Technology"` or `"Pop"`.
    public let genre: String?

    /// The price (`trackPrice`, falling back to `collectionPrice`/`price`), in ``currency``.
    public let price: Double?

    /// The ISO currency code for ``price``, e.g. `"USD"`.
    public let currency: String?

    /// A 30-second audio/video preview URL, when available (songs, music videos).
    public let previewURL: String?

    /// The two/three-letter storefront country, e.g. `"USA"`. Absent for some
    /// media types (apps, books).
    public let country: String?

    // MARK: - Media-specific fields

    /// The podcast's RSS feed URL. Present only for podcasts — pass it straight
    /// to `swift-podcast-metadata` to fetch the episode list.
    public let feedURL: String?

    /// The number of tracks/episodes in the collection, when applicable.
    public let trackCount: Int?

    /// A description / synopsis (`description`, falling back to `longDescription`).
    /// Present for apps, books, movies, and TV shows.
    public let description: String?

    /// The track duration in milliseconds (`trackTimeMillis`), when applicable.
    public let durationMillis: Int?

    // MARK: - Conveniences

    /// Whether this result is a podcast (and therefore carries a ``feedURL``).
    public var isPodcast: Bool { kind == "podcast" }

    public init(
        id: Int,
        wrapperType: String?,
        kind: String?,
        name: String?,
        artistName: String?,
        collectionName: String?,
        artworkURL: String?,
        viewURL: String?,
        releaseDate: Date?,
        genre: String?,
        price: Double?,
        currency: String?,
        previewURL: String?,
        country: String?,
        feedURL: String?,
        trackCount: Int?,
        description: String?,
        durationMillis: Int?
    ) {
        self.id = id
        self.wrapperType = wrapperType
        self.kind = kind
        self.name = name
        self.artistName = artistName
        self.collectionName = collectionName
        self.artworkURL = artworkURL
        self.viewURL = viewURL
        self.releaseDate = releaseDate
        self.genre = genre
        self.price = price
        self.currency = currency
        self.previewURL = previewURL
        self.country = country
        self.feedURL = feedURL
        self.trackCount = trackCount
        self.description = description
        self.durationMillis = durationMillis
    }
}
