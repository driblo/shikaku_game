import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const routeName = '/support';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSupportLink)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.supportHeadline,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.coffee),
                label: Text(l10n.supportDonateButton),
                onPressed: () {
                  // TODO(phase 6 / §9): wire to in_app_purchase or a
                  // simple external donation link.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
