//
//  ITunesClient.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performs GET requests against the keyless iTunes Search API.
///
/// No API key or authentication is required. The public API is rate-limited to
/// roughly 20 requests per minute; over-limit responses (`403`/`429`) map to
/// ``ITunesMetadataError/rateLimited``.
enum ITunesClient {

    /// The base host for the iTunes Search API.
    static let host = "https://itunes.apple.com"

    /// A browser-like User-Agent.
    ///
    /// The charts RSS feed returns an empty feed without one. It does not
    /// revive the customer-reviews feed — that is retired outright, and no
    /// agent string brings it back.
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"

    /// Performs a GET against `host + path` and returns the decoded JSON object.
    ///
    /// - Parameters:
    ///   - path: The request path (e.g. `/search` or `/lookup`).
    ///   - queryItems: The query parameters to append.
    /// - Returns: The top-level JSON object.
    static func get(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> [String: Any] {
        guard var components = URLComponents(string: host + path) else {
            throw ITunesMetadataError.networkError("Invalid request URL")
        }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else {
            throw ITunesMetadataError.networkError("Invalid request URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ITunesMetadataError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            switch http.statusCode {
            case 403, 429: throw ITunesMetadataError.rateLimited
            case 404: throw ITunesMetadataError.notFound
            default: throw ITunesMetadataError.apiError("HTTP \(http.statusCode)")
            }
        }

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw ITunesMetadataError.parsingError("Invalid JSON response")
        }

        // The API returns HTTP 200 with an `errorMessage` for bad parameter
        // combinations (e.g. an unsupported media/entity pairing).
        if let message = json["errorMessage"] as? String {
            throw ITunesMetadataError.apiError(message)
        }

        return json
    }
}
