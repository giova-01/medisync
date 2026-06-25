sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class BleFailure extends Failure {
  const BleFailure(super.message);
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
