/// Which catalog a piece of content belongs to. Shared across Favorites,
/// Watch History, and Downloads — all three key their storage off a
/// `(ContentType, streamId)` pair, matching the stream-ID namespaces used
/// by Xtream (and mirrored by `DemoContent`) for Live TV / Movies / Series.
enum ContentType { live, movie, series }
