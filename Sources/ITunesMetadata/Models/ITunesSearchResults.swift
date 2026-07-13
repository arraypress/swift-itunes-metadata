//
//  ITunesSearchResults.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The response from an iTunes search: a count plus the matching results.
public struct ITunesSearchResults: Sendable {

    /// The number of results the API reported (`resultCount`).
    public let resultCount: Int

    /// The matching results.
    public let results: [ITunesResult]

    public init(resultCount: Int, results: [ITunesResult]) {
        self.resultCount = resultCount
        self.results = results
    }
}
