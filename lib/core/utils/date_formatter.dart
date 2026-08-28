import 'package:intl/intl.dart';

/// Formats an Xtream `exp_date` (already parsed to [DateTime] by
/// `AuthRepositoryImpl`) as `DD MMM YYYY`, e.g. "24 Dec 2026".
String formatExpiryDate(DateTime? date) {
  if (date == null) return 'N/A';
  return DateFormat('dd MMM yyyy').format(date);
}
