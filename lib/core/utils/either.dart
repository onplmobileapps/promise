/// A result that is one of two things: a [Left], by convention a failure,
/// or a [Right], the value wanted. [fold] handles both.
sealed class Either<L, R> {
  const Either();

  /// [ifLeft] with a [Left]'s value, or [ifRight] with a [Right]'s.
  B fold<B>(B Function(L left) ifLeft, B Function(R right) ifRight);

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;
}

/// The failure side of an [Either].
final class Left<L, R> extends Either<L, R> {
  const Left(this.value);

  final L value;

  @override
  B fold<B>(B Function(L left) ifLeft, B Function(R right) ifRight) =>
      ifLeft(value);

  @override
  bool operator ==(Object other) => other is Left && other.value == value;

  @override
  int get hashCode => Object.hash(Left, value);

  @override
  String toString() => 'Left($value)';
}

/// The value side of an [Either].
final class Right<L, R> extends Either<L, R> {
  const Right(this.value);

  final R value;

  @override
  B fold<B>(B Function(L left) ifLeft, B Function(R right) ifRight) =>
      ifRight(value);

  @override
  bool operator ==(Object other) => other is Right && other.value == value;

  @override
  int get hashCode => Object.hash(Right, value);

  @override
  String toString() => 'Right($value)';
}
