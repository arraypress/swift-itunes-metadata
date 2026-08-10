//
//  AppStoreApp.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// An App Store or Mac App Store listing.
///
/// ``ITunesResult`` unifies every media type the Search API returns, which
/// means it drops the fields that only apps have — version, release notes,
/// ratings, minimum OS. Those are the interesting ones when the subject is an
/// app, so they get their own model rather than a pile of optionals bolted
/// onto the shared one.
public struct AppStoreApp: Sendable, Identifiable, Equatable {

    // MARK: Identity

    /// The App Store ID (`trackId`).
    public let id: Int

    /// The bundle identifier, e.g. `com.culturedcode.ThingsMac`.
    public let bundleID: String?

    /// The app's name.
    public let name: String

    /// `software`, `mac-software`, `software-bundle`…
    public let kind: String?

    /// The App Store page URL.
    public let url: String?

    // MARK: Seller

    /// The developer name as shown on the listing.
    public let seller: String?

    /// The developer's own website.
    public let sellerURL: String?

    /// The developer's App Store page.
    public let developerURL: String?

    // MARK: Version

    /// The current version string.
    public let version: String?

    /// When the current version shipped.
    ///
    /// Distinct from ``releaseDate``, which is when the app first appeared.
    /// The gap between them is how long a listing has been maintained.
    public let currentVersionDate: Date?

    /// When the app first shipped.
    public let releaseDate: Date?

    /// The "What's New" text for the current version.
    public let releaseNotes: String?

    // MARK: Ratings

    /// The mean star rating across all versions.
    ///
    /// Zero is a real answer, not a missing one — Mac App Store listings in
    /// particular often report no ratings at all through this API.
    public let rating: Double?

    /// How many ratings that mean is drawn from.
    public let ratingCount: Int?

    /// The mean rating for the current version only.
    public let currentVersionRating: Double?

    /// How many ratings the current version has.
    public let currentVersionRatingCount: Int?

    // MARK: Commerce

    /// The price in ``currency``. Zero for free apps.
    public let price: Double?

    /// The price as Apple formats it, e.g. `"$49.99"` or `"Free"`.
    public let formattedPrice: String?

    /// The ISO currency code.
    public let currency: String?

    // MARK: Listing

    /// The primary genre, e.g. `"Productivity"`.
    public let genre: String?

    /// Every genre the listing claims.
    public let genres: [String]

    /// The age rating, e.g. `"4+"`.
    public let contentRating: String?

    /// The download size in bytes.
    ///
    /// Apple sends this as a *string*; it is parsed here so callers do not
    /// each rediscover that.
    public let fileSizeBytes: Int?

    /// The minimum OS version the app runs on.
    public let minimumOSVersion: String?

    /// Localisations the listing advertises, as ISO codes.
    public let languages: [String]

    /// The full App Store description.
    public let description: String?

    /// The largest icon Apple offers.
    public let artworkURL: String?

    /// Screenshot URLs, in listing order.
    public let screenshotURLs: [String]

    // MARK: Conveniences

    /// Whether this is a Mac App Store listing.
    public var isMac: Bool { kind == "mac-software" }

    /// Whether the app costs nothing.
    public var isFree: Bool { (price ?? 0) == 0 }

    public init(
        id: Int,
        bundleID: String?,
        name: String,
        kind: String?,
        url: String?,
        seller: String?,
        sellerURL: String?,
        developerURL: String?,
        version: String?,
        currentVersionDate: Date?,
        releaseDate: Date?,
        releaseNotes: String?,
        rating: Double?,
        ratingCount: Int?,
        currentVersionRating: Double?,
        currentVersionRatingCount: Int?,
        price: Double?,
        formattedPrice: String?,
        currency: String?,
        genre: String?,
        genres: [String],
        contentRating: String?,
        fileSizeBytes: Int?,
        minimumOSVersion: String?,
        languages: [String],
        description: String?,
        artworkURL: String?,
        screenshotURLs: [String]
    ) {
        self.id = id
        self.bundleID = bundleID
        self.name = name
        self.kind = kind
        self.url = url
        self.seller = seller
        self.sellerURL = sellerURL
        self.developerURL = developerURL
        self.version = version
        self.currentVersionDate = currentVersionDate
        self.releaseDate = releaseDate
        self.releaseNotes = releaseNotes
        self.rating = rating
        self.ratingCount = ratingCount
        self.currentVersionRating = currentVersionRating
        self.currentVersionRatingCount = currentVersionRatingCount
        self.price = price
        self.formattedPrice = formattedPrice
        self.currency = currency
        self.genre = genre
        self.genres = genres
        self.contentRating = contentRating
        self.fileSizeBytes = fileSizeBytes
        self.minimumOSVersion = minimumOSVersion
        self.languages = languages
        self.description = description
        self.artworkURL = artworkURL
        self.screenshotURLs = screenshotURLs
    }
}
