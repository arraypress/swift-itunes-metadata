# Swift iTunes Metadata

A Swift library for searching Apple's iTunes catalog and looking up items by ID or app bundle ID — **podcasts, music, apps, movies, books, audiobooks, and TV** — using the public iTunes Search API.

**No API key. No authentication.** Just call and go.

## Features

- 🔓 **Keyless** — the iTunes Search API needs no token or login
- 🎧 **Podcasts** — every podcast result carries its RSS `feedURL`, ready to hand to [`swift-podcast-metadata`](https://github.com/arraypress) for the full episode list
- 🎵 **Music** — songs, albums, and music videos with prices, previews, and artwork
- 📱 **Apps** — search the App Store or look up by bundle identifier
- ⭐ **App Store reviews** — customer reviews (rating, title, body, author, version) via the keyless reviews feed
- 🏆 **Top charts** — top free/paid/grossing apps, albums, songs, podcasts, audiobooks
- 🎬 **Movies · 📚 Books · 🎙️ Audiobooks · 📺 TV** — one unified result model
- 🧩 **Unified results** — a single `ITunesResult` covers every media type; media-specific fields are optional
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS · Swift 6 · async/await
- 🛡️ **Typed error handling**

## The podcast pairing

The most useful field is `ITunesResult.feedURL`. iTunes is a great **discovery** index (search by name, get artwork, genre, episode count) but returns only podcast-level metadata — not episodes. Its `feedURL` is the podcast's RSS feed, which you pass straight to `swift-podcast-metadata` to fetch the episodes:

```swift
import ITunesMetadata

// 1. Discover the show on iTunes (search by name)
let results = try await ITunesMetadata.search("syntax", media: .podcast, limit: 5)
guard let show = results.results.first, let feed = show.feedURL else { return }

print("\(show.name ?? "") — \(show.trackCount ?? 0) episodes, genre \(show.genre ?? "?")")

// 2. Hand the RSS feed to swift-podcast-metadata for the episode list
// let podcast = try await PodcastMetadata.fetch(feed)
```

## Usage

```swift
import ITunesMetadata

// Search music (albums)
let albums = try await ITunesMetadata.search(
    "taylor swift", media: .music, entity: "album", limit: 10
)
for album in albums.results {
    print("\(album.artistName ?? "") – \(album.name ?? "") (\(album.price ?? 0) \(album.currency ?? ""))")
}

// Search the App Store
let apps = try await ITunesMetadata.search("notion", media: .software, limit: 5)

// Look up by iTunes ID
let byID = try await ITunesMetadata.lookup(id: 1253186678).first

// Look up an app by its bundle identifier
let chrome = try await ITunesMetadata.lookup(bundleId: "com.google.chrome.ios").first
print(chrome?.name ?? "not found")

// Pick a storefront (defaults to US, or ITUNES_COUNTRY)
let uk = try await ITunesMetadata.search("radio 4", media: .podcast, country: "GB")
```

### Media & entity

Pass an `ITunesMedia` to `media:` — `.podcast`, `.music`, `.software`, `.movie`, `.ebook`, `.audiobook`, `.tvShow`, `.musicVideo`, or `.all`. Narrow further with the optional `entity:` string, e.g. `media: .music, entity: "song"` vs `entity: "album"`. See Apple's Search API docs for the full entity list per media type.

### App Store reviews & charts

```swift
// Customer reviews for an app (by iTunes ID)
let reviews = try await ITunesMetadata.reviews(appID: 904237743, sortBy: .mostRecent)
for r in reviews {
    print("★\(r.rating) \(r.title) — \(r.author ?? "") (v\(r.version ?? "?"))")
    print(r.body)
}

// Top charts (apps, albums, songs, podcasts, audiobooks)
let topApps = try await ITunesMetadata.charts(.topFreeApps, limit: 25)
for app in topApps {
    print("#\(app.rank) \(app.name) — \(app.artist ?? "") (\(app.price ?? 0) \(app.currency ?? ""))")
}
```

## Models

| Type | Description |
|------|-------------|
| `ITunesResult` | Unified result: `id`, `wrapperType`, `kind`, `name`, `artistName`, `collectionName`, `artworkURL`, `viewURL`, `releaseDate`, `genre`, `price`, `currency`, `previewURL`, `country`, plus media-specific `feedURL`, `trackCount`, `description`, `durationMillis`, and an `isPodcast` convenience |
| `ITunesSearchResults` | `resultCount` + `[ITunesResult]` |
| `ITunesMedia` | `music`, `podcast`, `movie`, `ebook`, `software`, `audiobook`, `tvShow`, `musicVideo`, `all` (raw values match the API) |
| `ITunesReview` | `id`, `author`, `rating` (1–5), `title`, `body`, `version`, `voteCount`, `voteSum`, `updated` |
| `ITunesChartEntry` | `rank`, `id`, `bundleID`, `name`, `artist`, `price`, `currency`, `category`, `artworkURL`, `storeURL`, `releaseDate` |
| `ITunesChart` / `ITunesReviewSort` | Chart-feed and review-sort enums |
| `ITunesMetadata.Configuration` | Storefront `country` (defaults to `US` / `ITUNES_COUNTRY`) |
| `ITunesMetadataError` | Typed errors with `errorDescription` |

Fields vary by media type, so media-specific ones are optional: e.g. albums have no `trackName`/`kind` (`name` falls back to `collectionName`, `id` to `collectionId`), apps and books have no `country`, and only podcasts have a `feedURL`.

## Rate limits

The public API allows roughly **20 requests per minute**; over-limit responses surface as `ITunesMetadataError.rateLimited`.

## Testing

```bash
swift test                          # offline unit tests (fixtures)
ITUNES_LIVE_TESTS=1 swift test      # + keyless live search + lookup
ITUNES_LIVE_TESTS=1 ITUNES_PRINT=1 swift test   # + print live output
```

## License

MIT

## Author

David Sherlock
