sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  T fold<T>(T Function(L l) onLeft, T Function(R r) onRight) {
    return switch (this) {
      Left<L, R>(:final value) => onLeft(value),
      Right<L, R>(:final value) => onRight(value),
    };
  }
}

final class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
}

final class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
}
