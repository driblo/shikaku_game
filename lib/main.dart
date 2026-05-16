import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge: draw under bars but keep them visible and tappable.
  // Per architecture plan §7 feature 3: never call
  // SystemChrome.setEnabledSystemUIMode with immersive*/leanBack.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(const ProviderScope(child: ShikakuApp()));
}
