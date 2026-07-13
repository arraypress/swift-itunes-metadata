//
//  ITunesRSSParser.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses Apple's RSS-feed JSON (customer reviews and top charts), whose shape
/// differs from the Search API — values are wrapped as `{ "label": … }` and
/// attributes live under `{ "attributes": … }`.
enum ITunesRSSParser {

    // MARK: - Reviews

    static func reviews(_ json: [String: Any]) -> [ITunesReview] {
        entries(in: json).compactMap { entry in
            // Review entries carry `im:rating`; the occasional app-summary entry does not.
            guard let ratingText = label(entry["im:rating"]), let rating = Int(ratingText) else { return nil }
            return ITunesReview(
                id: Int(label(entry["id"]) ?? "") ?? 0,
                author: label(dict(entry["author"])?["name"]),
                rating: rating,
                title: label(entry["title"]) ?? "",
                body: label(entry["content"]) ?? "",
                version: label(entry["im:version"]),
                voteCount: Int(label(entry["im:voteCount"]) ?? ""),
                voteSum: Int(label(entry["im:voteSum"]) ?? ""),
                updated: date(label(entry["updated"]))
            )
        }
    }

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
