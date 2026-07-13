//
//  ITunesMetadataError.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when calling the iTunes Search API.
public enum ITunesMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// The supplied search term or lookup identifier was empty or invalid.
    case invalidInput

    /// The requested resource was not found (`404`).
    case notFound

    /// iTunes is rate-limiting requests (`403`/`429`). The public API allows
    /// roughly 20 requests per minute.
    case rateLimited

    /// iTunes returned an error payload (e.g. an unsupported `media`/`entity`
    /// combination).
    case apiError(String)

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the response.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "The search term or lookup identifier was empty or invalid."
        case .notFound:
            return "The requested iTunes resource was not found."
        case .rateLimited:
            return "iTunes is rate-limiting requests (roughly 20 requests per minute)."
        case .apiError(let message):
            return "iTunes API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
