/// Maps a provider's free-text category names onto the fixed, semantic rows
/// the UI wants to show ("Sports", "Arabic", "Kids", "Action"…).
///
/// WHY THIS EXISTS: Xtream Codes has no genre taxonomy. Every provider
/// invents their own category names — "|AR| SPORTS", "Sports HD", "beIN
/// Sports", "رياضة" — so a hardcoded row like "Sports" can only be filled
/// by *matching* those names. Rows whose keywords match nothing simply
/// don't render (see the screens' `_buildCuratedRows`), and every category
/// that didn't land in a curated row still gets its own row underneath, so
/// nothing in the catalog is ever hidden from the user.
///
/// Matching is case-insensitive substring, deliberately: provider names are
/// full of separators, quality tags and country prefixes, so exact matching
/// would miss nearly everything.
abstract class CategoryMatcher {
  CategoryMatcher._();

  /// Latin + Arabic-script keywords, since Arabic-language IPTV catalogs
  /// commonly name categories in Arabic.
  static const Map<CuratedBucket, List<String>> keywords = {
    CuratedBucket.sports: ['sport', 'bein', 'espn', 'football', 'soccer', 'nba', 'ufc', 'رياضة', 'رياضه'],
    CuratedBucket.movies: ['movie', 'cinema', 'film', 'أفلام', 'افلام', 'سينما'],
    CuratedBucket.news: ['news', 'اخبار', 'أخبار'],
    CuratedBucket.kids: ['kid', 'child', 'cartoon', 'anime', 'disney', 'nick', 'atfal', 'أطفال', 'اطفال', 'كرتون'],
    CuratedBucket.arabic: ['arab', 'arabic', 'عرب', 'عربي', 'عربية', 'مصر', 'egypt', 'ksa', 'mbc', 'osn'],
    CuratedBucket.foreign: ['english', 'foreign', 'hollywood', 'usa', 'uk', 'french', 'german', 'spanish', 'turkish', 'indian', 'bollywood'],
    CuratedBucket.action: ['action', 'adventure', 'thriller', 'اكشن', 'أكشن'],
    CuratedBucket.comedy: ['comedy', 'كوميدي', 'كوميديا'],
    CuratedBucket.horror: ['horror', 'scary', 'رعب'],
    CuratedBucket.drama: ['drama', 'دراما'],
    CuratedBucket.documentary: ['document', 'nat geo', 'discovery', 'history', 'وثائقي', 'وثائقيات'],
    CuratedBucket.completed: ['complete', 'ended', 'finished', 'full series', 'مكتمل', 'مكتملة'],
  };

  /// True when [categoryName] looks like it belongs to [bucket].
  static bool matches(String categoryName, CuratedBucket bucket) {
    final haystack = categoryName.toLowerCase();
    return keywords[bucket]!.any(haystack.contains);
  }

  /// IDs of every category matching [bucket], given `(id, name)` pairs.
  static Set<String> idsFor(
    CuratedBucket bucket,
    Iterable<({String id, String name})> categories,
  ) {
    return {
      for (final category in categories)
        if (matches(category.name, bucket)) category.id,
    };
  }
}

/// The semantic rows the Live TV / Movies / Series screens can surface.
enum CuratedBucket {
  sports('Sports'),
  movies('Movies'),
  news('News'),
  kids('Kids'),
  arabic('Arabic'),
  foreign('Foreign'),
  action('Action'),
  comedy('Comedy'),
  horror('Horror'),
  drama('Drama'),
  documentary('Documentaries'),
  completed('Completed Series');

  /// Row heading shown in the UI.
  final String label;
  const CuratedBucket(this.label);
}
