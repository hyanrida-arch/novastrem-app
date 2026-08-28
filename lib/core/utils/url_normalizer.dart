/// Prepends `http://` to a user-entered URL that's missing a scheme, and
/// strips a trailing slash. Shared by [XtreamUrlBuilder] and the M3U login
/// path so both handle the common "pasted the address without http://"
/// mistake the same way.
String normalizeUrl(String url) {
  var trimmed = url.trim();
  if (!trimmed.contains('://')) {
    trimmed = 'http://$trimmed';
  }
  return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
}
