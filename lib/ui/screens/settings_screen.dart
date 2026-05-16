import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'support_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              onTap: () {
                // TODO(phase 1): show language picker (native names,
                // alphabetical by English name).
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text(l10n.settingsSupportLink),
              onTap: () => Navigator.of(context)
                  .pushNamed(SupportScreen.routeName),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.settingsOpenSourceLicenses),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Shikaku',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
