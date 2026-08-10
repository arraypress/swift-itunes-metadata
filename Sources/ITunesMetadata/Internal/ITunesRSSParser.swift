//
//  ITunesRSSParser.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses Apple's top-charts RSS JSON, whose shape
/// differs from the Search API — values are wrapped as `{ "label": … }` and
/// attributes live under `{ "attributes": … }`.
///
/// Reviews used to be parsed here too. That feed is retired; see
/// ``AppStoreReviewParser`` for where they come from now.
enum ITunesRSSParser {

    // MARK: - Charts

    static func chartEntries(_ json: [String: Any]) -> [ITunesChartEntry] {
        entries(in: json).enumerated().map { index, entry in
            let idAttributes = attributes(entry["id"])
            let priceAttributes = attributes(entry["im:price"])
            let categoryAttributes = attributes(entry["category"])
            let images = (entry["im:image"] as? [[String: Any]]) ?? []

            return ITunesChartEntry(
                rank: index + 1,
                id: Int(idAttributes?["im:id"] as? String ?? "") ?? 0,
                bundleID: idAttributes?["im:bundleId"] as? String,
                name: label(entry["im:name"]) ?? "",
                artist: label(entry["im:artist"]),
                price: (priceAttributes?["amount"] as? String).flatMap(Double.init),
                currency: priceAttributes?["currency"] as? String,
                category: categoryAttributes?["label"] as? String,
                artworkURL: label(images.last),
                storeURL: label(entry["id"]),
                releaseDate: date(label(entry["im:releaseDate"]))
            )
        }
    }

    // MARK: - Helpers

    /// The `feed.entry` list, coercing a single-object entry into a one-item array.
    private static func entries(in json: [String: Any]) -> [[String: Any]] {
        guard let feed = json["feed"] as? [String: Any] else { return [] }
        if let array = feed["entry"] as? [[String: Any]] { return array }
        if let single = feed["entry"] as? [String: Any] { return [single] }
        return []
    }

    private static func label(_ value: Any?) -> String? {
        let text = (value as? [String: Any])?["label"] as? String
        return (text?.isEmpty == false) ? text : nil
    }

    private static func dict(_ value: Any?) -> [String: Any]? {
        value as? [String: Any]
    }

    private static func attributes(_ value: Any?) -> [String: Any]? {
        (value as? [String: Any])?["attributes"] as? [String: Any]
    }

    private static func date(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
