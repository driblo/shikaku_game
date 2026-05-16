import 'package:flutter/widgets.dart';

typedef LifecycleCallback = void Function(AppLifecycleState state);

class LifecycleObserver with WidgetsBindingObserver {
  LifecycleObserver(this._onChange);

  final LifecycleCallback _onChange;

  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onChange(state);
  }
}
