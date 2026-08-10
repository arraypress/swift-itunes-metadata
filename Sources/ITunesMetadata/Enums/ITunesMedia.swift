//
//  ITunesMedia.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The media type to search or filter by.
///
/// Raw values map directly to the iTunes Search API `media` parameter.
///
/// Verified against the live API in August 2026: `software`, `music`,
/// `podcast`, `ebook`, `audiobook` and `musicVideo` all return results.
/// `movie` and `tvShow` do not, and are deprecated below.
public enum ITunesMedia: String, Sendable, CaseIterable {
    /// Songs, albums, and music videos.
    case music
    /// Podcasts (each result carries an RSS ``ITunesResult/feedURL``).
    case podcast
    /// Feature films and shorts.
    ///
    /// - Warning: Apple no longer serves film through the Search API. Every
    ///   query returns zero results in every storefront, and even a direct
    ///   `lookup` of a known film ID comes back empty. Nothing about the
    ///   response signals a failure — it is a successful, empty answer — so
    ///   this is kept and marked rather than quietly left as a trap.
    @available(*, deprecated, message: "Apple no longer serves film through the Search API; this always returns zero results.")
    case movie
    /// Books from Apple Books.
    case ebook
    /// iOS/macOS apps from the App Store.
    case software
    /// Audiobooks.
    case audiobook
    /// TV episodes and seasons.
    ///
    /// - Warning: Retired alongside ``movie``. Returns zero results in every
    ///   storefront.
    @available(*, deprecated, message: "Apple no longer serves TV through the Search API; this always returns zero results.")
    case tvShow
    /// Music videos. Still served, unlike ``movie`` and ``tvShow``.
    case musicVideo
    /// Every media type (the API default).
    case all

    /// The media types Apple actually serves.
    ///
    /// Written out rather than synthesised so ``movie`` and ``tvShow`` are
    /// absent: anything enumerating this list is offering choices to a caller,
    /// and a choice that always returns nothing is worse than no choice.
    public static var allCases: [ITunesMedia] {
        [.music, .podcast, .ebook, .software, .audiobook, .musicVideo, .all]
    }
}
