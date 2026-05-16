/// Typed callback aliases used across the app. Kept deliberately small —
/// no global event bus yet (over-engineering for a single-player puzzle).
typedef VoidCb = void Function();
typedef ValueCb<T> = void Function(T value);
