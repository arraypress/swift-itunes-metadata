//
//  ITunesChart.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// An Apple "top charts" RSS feed.
///
/// The raw value is the feed path segment used by
/// ``ITunesMetadata/charts(_:limit:country:configuration:)``.
public enum ITunesChart: String, Sendable {
    /// Top free apps.
    case topFreeApps = "topfreeapplications"
    /// Top paid apps.
    case topPaidApps = "toppaidapplications"
    /// Top grossing apps.
    case topGrossingApps = "topgrossingapplications"
    /// New apps.
    case newApps = "newapplications"
    /// Top albums.
    case topAlbums = "topalbums"
    /// Top songs.
    case topSongs = "topsongs"
    /// Top podcasts.
    case topPodcasts = "toppodcasts"
    /// Top audiobooks.
    case topAudiobooks = "topaudiobooks"
}
