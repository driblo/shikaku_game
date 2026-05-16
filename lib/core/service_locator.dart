/// Minimal hand-rolled locator. Riverpod is the primary DI; this is for the
/// rare cross-cutting singleton that needs to live outside the widget tree
/// (e.g. an AudioService accessed from a lifecycle observer).
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, Object> _services = {};

  void register<T extends Object>(T service) => _services[T] = service;
  T get<T extends Object>() => _services[T] as T;
  bool has<T extends Object>() => _services.containsKey(T);
}
