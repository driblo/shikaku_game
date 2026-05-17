import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  static const routeName = '/menu';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(LevelSelectScreen.routeName),
                child: Text(l10n.menuPlay),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(SettingsScreen.routeName),
                child: Text(l10n.menuSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
