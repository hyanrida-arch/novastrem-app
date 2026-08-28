import 'package:dio/dio.dart';

import '../error/failures.dart';

/// Central place that turns a [DioException] into a domain-level [Failure].
/// Every repository's catch block should funnel through this instead of
/// re-implementing the same switch statement.
///
/// Messages are kept specific (timeout vs. unreachable host vs. server
/// error) rather than a single generic "no internet" string — a malformed
/// server URL, a DNS failure, and an actual offline device all surface
/// differently to Dio, and collapsing them into one message makes this
/// class of bug much harder for users (and us) to diagnose.
Failure mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
      return const NetworkFailure('Connection timed out. Check the server address and try again.');
    case DioExceptionType.receiveTimeout:
      return const NetworkFailure('Server took too long to respond. Try again.');
    case DioExceptionType.connectionError:
      return const NetworkFailure(
        "Couldn't reach the server. Double-check the URL/port and that the device has internet access.",
      );
    case DioExceptionType.badResponse:
      // Surface the actual HTTP status rather than a bare "Server error" —
      // 403 (blocked), 404 (wrong path), 5xx (panel down) all mean
      // different things and are worth telling apart at a glance.
      final status = e.response?.statusCode;
      return ServerFailure(status != null ? 'Server error ($status). Please try again.' : 'Server error. Please try again.');
    case DioExceptionType.cancel:
      return const ServerFailure('Request was interrupted. Please try again.');
    default:
      return const ServerFailure();
  }
}
