import 'package:equatable/equatable.dart';

/// Base type for all recoverable errors surfaced to the presentation layer.
///
/// Data sources throw raw exceptions; repositories catch them and map them
/// to a [Failure] so the UI never has to deal with Dio/Hive-specific types.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Network-level problems: timeouts, no connectivity, DNS failures.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Server responded, but with an error status or unexpected payload shape.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

/// Xtream Codes / M3U credentials were rejected.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Invalid credentials. Please check your details.']);
}

/// Local cache (Hive/SharedPreferences) read/write problem.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error.']);
}

/// Fallback for anything unforeseen.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}

/// The text to put in front of a user for an error surfaced by a provider.
///
/// Riverpod hands `.when(error:)` the thrown object, and our providers
/// rethrow domain [Failure]s. Calling `toString()` on those yields the
/// Equatable form — `ServerFailure(Your subscription status is "Expired"…)` —
/// which leaks a class name into the UI. Use the written-for-humans message
/// when we have one, and fall back to `toString()` otherwise.
String describeError(Object error) =>
    error is Failure ? error.message : error.toString();
