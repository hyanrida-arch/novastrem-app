import '../error/failures.dart';

/// A minimal `Either<Failure, T>` substitute so the domain layer doesn't
/// need to pull in a functional-programming package like dartz just for
/// error handling. Usecases/repositories return `Result<T>`; the UI switches
/// on [isSuccess] (or uses [when]) instead of throwing.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = Error<T>;

  bool get isSuccess => this is Success<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Error<T>) return failure(self.failure);
    throw StateError('Unreachable');
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}
