/// Xtream Codes has no reliable dedicated "release year" field on VOD/series
/// list entries (some panels include one, most don't) — but the vast
/// majority of real-world catalogs embed it in the title itself, e.g.
/// "Deadpool & Wolverine (2024)". Extracting it from there is the same
/// trick most Smarters-style clients use, and degrades gracefully (returns
/// null, filter chip just won't match) for panels that don't follow the
/// convention.
int? extractYearFromTitle(String title) {
  final match = _trailingYear.firstMatch(title);
  if (match == null) return null;
  final digits = match.group(0)!.replaceAll(RegExp(r'[()]'), '').trim();
  return int.tryParse(digits);
}

/// Drops the trailing "(YYYY)" so a hero banner can show the year in its
/// own metadata line without it appearing twice ("Sintel" + "2010 · Sci-Fi"
/// rather than "Sintel (2010)" + "2010 · Sci-Fi").
String stripYearFromTitle(String title) => title.replaceAll(_trailingYear, '').trim();

final RegExp _trailingYear = RegExp(r'\((19|20)\d{2}\)\s*$');
