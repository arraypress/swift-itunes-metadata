//
//  AppStorePage.swift
//  ITunesMetadata
//
//  Created by David Sherlock on 2026.
//
//  Reads the JSON the App Store website renders into its own page.
//
//  Apple retired the customer-reviews RSS feed
//  (`itunes.apple.com/<cc>/rss/customerreviews/`). It still answers 200 with a
//  well-formed feed envelope — and zero entries, for every app, in every
//  storefront, in JSON and XML alike. Nothing about the response says it
//  failed, which is why the old implementation went on reporting success while
//  returning nothing.
//
//  The reviews now arrive server-rendered inside
//  `<script id="serialized-server-data" type="application/json">` on
//  `apps.apple.com`. That is also why there is no token to borrow: the page's
//  own bundle reads `process.env.MEDIA_API_TOKEN`, a build-time server
//  variable, so the browser never holds a credential and
//  `amp-api.apps.apple.com` answers 401 to everyone else.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetches an App Store product page and extracts its embedded JSON.
enum AppStorePage {

    static let host = "https://apps.apple.com"

    /// The server-rendered JSON blob for one app.
    ///
    /// - Parameters:
    ///   - appID: The app's numeric App Store ID.
    ///   - country: The storefront country code.
    ///   - userAgent: The agent to present.
    /// - Returns: The decoded contents of the `serialized-server-data` script.
    static func serializedData(
        appID: Int,
        country: String,
        userAgent: String
    ) async throws -> Any {
        // `?see-all=reviews` renders the dedicated reviews view, which carries
        // ten. The plain product page carries eight — same request, 25% fewer.
        let path = "/\(country.lowercased())/app/id\(appID)?see-all=reviews"
        guard let url = URL(string: host + path) else {
            throw ITunesMetadataError.networkError("Invalid App Store URL")
        }

        var request = URLRequest(url: url)
        request.setValue("text/html", forHTTPHeaderField: "Accept")
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

        let html = String(decoding: data, as: UTF8.self)
        guard let json = extractSerializedData(from: html) else {
            throw ITunesMetadataError.parsingError(
                "No serialized-server-data block on the App Store page for \(appID)"
            )
        }
        return json
    }

    /// Pulls the `serialized-server-data` script's contents out of page HTML.
    ///
    /// Scans for the script tag rather than parsing the document: the page is
    /// close to a megabyte and this is the only element wanted from it.
    static func extractSerializedData(from html: String) -> Any? {
        let marker = "id=\"serialized-server-data\""
        guard let idRange = html.range(of: marker),
              let openEnd = html.range(of: ">", range: idRange.upperBound..<html.endIndex),
              let closeStart = html.range(of: "</script>", range: openEnd.upperBound..<html.endIndex)
        else { return nil }

        let body = html[openEnd.upperBound..<closeStart.lowerBound]
        return try? JSONSerialization.jsonObject(
            with: Data(body.utf8),
            options: [.fragmentsAllowed]
        )
    }
}
