//
//  ITunesReview.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single App Store customer review.
///
/// Fetched from the keyless customer-reviews RSS feed via
/// ``ITunesMetadata/reviews(appID:sortBy:page:country:configuration:)``.
public struct ITunesReview: Sendable, Identifiable {

    /// The review ID.
    public let id: Int

    /// The reviewer's nickname.
    public let author: String?

    /// The star rating, `1...5`.
    public let rating: Int

    /// The review title.
    public let title: String

    /// The review body text.
    public let body: String

    /// The app version the review was written against.
    public let version: String?

    /// The number of "was this helpful" votes.
    public let voteCount: Int?

    /// The sum of helpful votes.
    public let voteSum: Int?

    /// When the review was posted/updated.
    public let updated: Date?

    public init(
        id: Int, author: String?, rating: Int, title: String, body: String,
        version: String?, voteCount: Int?, voteSum: Int?, updated: Date?
    ) {
        self.id = id
        self.author = author
        self.rating = rating
        self.title = title
        self.body = body
        self.version = version
        self.voteCount = voteCount
        self.voteSum = voteSum
        self.updated = updated
    }
}
