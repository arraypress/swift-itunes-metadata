//
//  ITunesParser.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses iTunes Search API response objects into typed models.
enum ITunesParser {

    // MARK: - Search / Lookup

    /// Parses a full search/lookup envelope (`{ resultCount, results }`).
    static func searchResults(_ d: [String: Any]) -> ITunesSearchResults {
        let results = resultList(d)
        return ITunesSearchResults(
            resultCount: intValue(d["resultCount"]) ?? results.count,
            results: results
        )
    }

    /// Parses just the `results` array (used by lookup endpoints).
    static func resultList(_ d: [String: Any]) -> [ITunesResult] {
        (d["results"] as? [[String: Any]] ?? []).map(result)
    }

    // MARK: - Result

    /// Parses a single heterogeneous result object.
    static func result(_ d: [String: Any]) -> ITunesResult {
        ITunesResult(
            id: intValue(d["trackId"]) ?? intValue(d["collectionId"]) ?? 0,
            wrapperType: nonEmpty(d["wrapperType"]),
            kind: nonEmpty(d["kind"]),
            name: nonEmpty(d["trackName"]) ?? nonEmpty(d["collectionName"]),
            artistName: nonEmpty(d["artistName"]),
            collectionName: nonEmpty(d["collectionName"]),
            artworkURL: nonEmpty(d["artworkUrl100"]) ?? nonEmpty(d["artworkUrl60"]),
            viewURL: nonEmpty(d["trackViewUrl"]) ?? nonEmpty(d["collectionViewUrl"]),
            releaseDate: isoDate(d["releaseDate"]),
            genre: nonEmpty(d["primaryGenreName"]),
            price: doubleValue(d["trackPrice"]) ?? doubleValue(d["collectionPrice"]) ?? doubleValue(d["price"]),
            currency: nonEmpty(d["currency"]),
            previewURL: nonEmpty(d["previewUrl"]),
            country: nonEmpty(d["country"]),
            feedURL: nonEmpty(d["feedUrl"]),
            trackCount: intValue(d["trackCount"]),
            description: nonEmpty(d["description"]) ?? nonEmpty(d["longDescription"]),
            durationMillis: intValue(d["trackTimeMillis"])
        )
    }

    // MARK: - Helpers

    /// Returns the string if non-empty, else `nil`. Accepts non-string values as `nil`.
    private static func nonEmpty(_ value: Any?) -> String? {
        guard let s = value as? String, !s.isEmpty else { return nil }
        return s
    }

    /// Parses an iTunes ISO-8601 timestamp (e.g. `"2026-07-08T11:00:00Z"`).
    private static func isoDate(_ value: Any?) -> Date? {
        guard let s = value as? String, !s.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: s) { return d }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: s)
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String { return Int(s) }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let s = value as? String { return Double(s) }
        return nil
    }
}
