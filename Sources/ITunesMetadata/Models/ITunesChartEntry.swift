//
//  ITunesChartEntry.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single entry in an Apple top-charts feed (app, album, song, podcast…).
///
/// Fetched via ``ITunesMetadata/charts(_:limit:country:configuration:)``.
public struct ITunesChartEntry: Sendable, Identifiable {

    /// The chart position (1-based).
    public let rank: Int

    /// The item's iTunes ID.
    public let id: Int

    /// The app bundle identifier (apps only).
    public let bundleID: String?

    /// The item name.
    public let name: String

    /// The artist / developer.
    public let artist: String?

    /// The price (`0` for free).
    public let price: Double?

    /// The currency code.
    public let currency: String?

    /// The category / genre.
    public let category: String?

    /// The largest artwork URL provided.
    public let artworkURL: String?

    /// The App Store / iTunes page URL.
    public let storeURL: String?

    /// The release date.
    public let releaseDate: Date?

    public init(
        rank: Int, id: Int, bundleID: String?, name: String, artist: String?,
        price: Double?, currency: String?, category: String?, artworkURL: String?,
        storeURL: String?, releaseDate: Date?
    ) {
        self.rank = rank
        self.id = id
        self.bundleID = bundleID
        self.name = name
        self.artist = artist
        self.price = price
        self.currency = currency
        self.category = category
        self.artworkURL = artworkURL
        self.storeURL = storeURL
        self.releaseDate = releaseDate
    }
}
