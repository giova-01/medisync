import 'package:medisync/core/errors/either.dart';
import 'package:medisync/core/errors/failures.dart';

/// Base contract for all use cases.
abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// Placeholder for use cases that require no input parameters.
class NoParams {
  const NoParams();
}
