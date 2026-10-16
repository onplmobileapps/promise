import 'package:flutter/foundation.dart';

/// Value equality from [props]: two objects of the same type are equal when
/// their props are, lists, sets and maps among them compared by what they
/// hold. For states and models compared by blocs and widgets.
@immutable
abstract class Equatable {
  const Equatable();

  /// What makes two of these the same.
  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Equatable &&
          other.runtimeType == runtimeType &&
          _deepEquals(props, other.props);

  @override
  int get hashCode => Object.hash(runtimeType, _deepHash(props));

  @override
  String toString() => '$runtimeType(${props.join(', ')})';
}

bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Set && b is Set) {
    return a.length == b.length && a.every(b.contains);
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  return a == b;
}

int _deepHash(Object? value) => switch (value) {
  final List list => Object.hashAll(list.map(_deepHash)),
  final Set set => Object.hashAllUnordered(set.map(_deepHash)),
  final Map map => Object.hashAllUnordered(
    map.entries.map((e) => Object.hash(_deepHash(e.key), _deepHash(e.value))),
  ),
  _ => value.hashCode,
};
