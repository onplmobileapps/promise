/// The app's service locator. Registrations live in `app/di`; anything
/// registered is fetched with `sl<Type>()`.
final sl = ServiceLocator();

/// Hands out the app's services by type: one made up front, one made the
/// first time it is asked for, or a fresh one each time.
class ServiceLocator {
  final Map<Type, Object Function()> _makers = {};

  /// Whether a type may be registered again, replacing what was there, as
  /// tests do; otherwise registering twice is a mistake.
  bool allowReassignment = false;

  /// The service registered for [T].
  T call<T extends Object>() {
    final make = _makers[T];
    if (make == null) {
      throw StateError('$T is not registered with the service locator.');
    }
    return make() as T;
  }

  /// Whether something is registered for [T].
  bool isRegistered<T extends Object>() => _makers.containsKey(T);

  /// [instance], every time [T] is asked for.
  void registerSingleton<T extends Object>(T instance) =>
      _register<T>(() => instance);

  /// One [T], made by [make] the first time it is asked for.
  void registerLazySingleton<T extends Object>(T Function() make) {
    T? instance;
    _register<T>(() => instance ??= make());
  }

  /// A new [T] from [make] each time it is asked for.
  void registerFactory<T extends Object>(T Function() make) =>
      _register<T>(make);

  void _register<T extends Object>(Object Function() make) {
    if (!allowReassignment && _makers.containsKey(T)) {
      throw StateError('$T is already registered with the service locator.');
    }
    _makers[T] = make;
  }

  /// Forgets everything registered, as between tests.
  Future<void> reset() async {
    _makers.clear();
  }
}
