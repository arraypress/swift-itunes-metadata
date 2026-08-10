//
//  ITunesReview.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single App Store customer review.
///
/// Read from the App Store product page via
/// ``ITunesMetadata/reviews(appID:country:configuration:)``. See that method
/// for what the public source will and will not give you.
///
/// The old RSS feed carried `im:version`, `im:voteCount` and `im:voteSum`.
/// The page does not, and those fields are gone rather than left permanently
/// nil — an always-empty field is a promise the type cannot keep.
public struct ITunesReview: Sendable, Identifiable, Equatable {

    /// The review ID. Past 32 bits on established apps.
    public let id: Int

    /// The reviewer's nickname, when the page carries one.
    public let author: String?

    /// The star rating, `1...5`.
    ///
    /// This is the rating the reviewer actually submitted, which is not always
    /// the rating their prose implies — five stars above "worst app ever" is a
    /// real and reasonably common combination, not a parsing error.
    public let rating: Int

    /// The review title.
    public let title: String

    /// The review body.
    public let body: String

    /// When the review was posted.
    public let date: Date?

    public init(
        id: Int,
        author: String?,
        rating: Int,
        title: String,
        body: String,
        date: Date?
    ) {
        self.id = id
        self.author = author
        self.rating = rating
        self.title = title
        self.body = body
        self.date = date
    }
}
