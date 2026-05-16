import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
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
                onPressed: () {
                  // TODO(phase 4): route to LevelSelect once gameplay lands.
                },
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
