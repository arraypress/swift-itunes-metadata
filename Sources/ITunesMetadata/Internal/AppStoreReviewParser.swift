//
//  AppStoreReviewParser.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Extracts customer reviews from an App Store page's embedded JSON.
enum AppStoreReviewParser {

    /// Objects tagged with this `$kind` are reviews.
    private static let reviewKind = "Review"

    /// Markers proving the page carried a reviews section at all.
    ///
    /// Used to tell "this app has no reviews" apart from "Apple changed the
    /// page and we are now parsing nothing" — outcomes that look identical if
    /// you only count results.
    private static let shelfMarkers = ["allProductReviews", "userProductReviews", "productReview"]

    /// Every distinct review in the blob.
    ///
    /// The same review is emitted several times over — once per shelf that
    /// displays it — so results are deduplicated by ID. A plain walk of the
    /// tree reports 40 reviews for a page that carries 8.
    static func reviews(in json: Any) -> [ITunesReview] {
        var collected: [ITunesReview] = []
        var seen = Set<Int>()

        func walk(_ node: Any) {
            if let object = node as? [String: Any] {
                if object["$kind"] as? String == reviewKind,
                   let review = review(from: object),
                   seen.insert(review.id).inserted {
                    collected.append(review)
                }
                for value in object.values { walk(value) }
            } else if let array = node as? [Any] {
                for value in array { walk(value) }
            }
        }
        walk(json)

        // Newest first. The page's own order is "most helpful", which is not
        // reproducible from the data, so imposing a defined order beats
        // preserving one the caller cannot reason about.
        return collected.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    /// Whether the page actually contained a reviews section.
    static func hasReviewSection(in json: Any) -> Bool {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.fragmentsAllowed]),
              let text = String(data: data, encoding: .utf8) else { return false }
        return shelfMarkers.contains { text.contains($0) }
    }

    // MARK: - Mapping

    private static func review(from object: [String: Any]) -> ITunesReview? {
        guard let id = integer(object["id"]) else { return nil }

        // `contents` is a plain string today, but the surrounding shelves use
        // arrays of strings for other body-like fields, so both are accepted.
        let body: String
        switch object["contents"] {
        case let text as String: body = text
        case let parts as [String]: body = parts.joined(separator: "\n\n")
        default: body = ""
        }

        return ITunesReview(
            id: id,
            author: nonEmpty(object["reviewerName"] as? String),
            rating: (object["rating"] as? Int) ?? Int(object["rating"] as? String ?? "") ?? 0,
            title: (object["title"] as? String) ?? "",
            body: body,
            date: date(object["date"] as? String)
        )
    }

    /// Review IDs arrive as strings and run past 32 bits (`13539617732`).
    private static func integer(_ value: Any?) -> Int? {
        if let number = value as? Int { return number }
        if let text = value as? String { return Int(text) }
        return nil
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty, value != "* null *" else { return nil }
        return value
    }

    private static func date(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
