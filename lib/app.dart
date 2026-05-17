import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/level_list_screen.dart';
import 'ui/screens/level_select_screen.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/support_screen.dart';

class ShikakuApp extends StatelessWidget {
  const ShikakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shikaku',
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B6CD8),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B6CD8),
        brightness: Brightness.dark,
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LevelSelectScreen.routeName: (_) => const LevelSelectScreen(),
        MainMenuScreen.routeName: (_) => const MainMenuScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        SupportScreen.routeName: (_) => const SupportScreen(),
        LevelListScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments
              as Map<String, dynamic>;
          return LevelListScreen(difficulty: args['difficulty'] as String);
        },
        GameScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments
              as Map<String, dynamic>;
          return GameScreen(
            difficulty: args['difficulty'] as String,
            index: args['index'] as int,
          );
        },
      },
    );
  }
}
