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
public enum ITunesMedia: String, Sendable, CaseIterable {
    /// Songs, albums, and music videos.
    case music
    /// Podcasts (each result carries an RSS ``ITunesResult/feedURL``).
    case podcast
    /// Feature films and shorts.
    case movie
    /// Books from Apple Books.
    case ebook
    /// iOS/macOS apps from the App Store.
    case software
    /// Audiobooks.
    case audiobook
    /// TV episodes and seasons.
    case tvShow
    /// Music videos.
    case musicVideo
    /// Every media type (the API default).
    case all
}
