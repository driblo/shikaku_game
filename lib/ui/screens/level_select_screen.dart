import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'level_list_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  static const routeName = '/level-select';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.levelSelectTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DifficultyCard(
              label: l10n.levelSelectEasy,
              icon: Icons.sentiment_satisfied_alt,
              color: Colors.green,
              onTap: () => _startGame(context, 'easy'),
            ),
            const SizedBox(height: 12),
            _DifficultyCard(
              label: l10n.levelSelectMedium,
              icon: Icons.sentiment_neutral,
              color: Colors.orange,
              onTap: () => _startGame(context, 'medium'),
            ),
            const SizedBox(height: 12),
            _DifficultyCard(
              label: l10n.levelSelectHard,
              icon: Icons.sentiment_very_dissatisfied,
              color: Colors.red,
              onTap: () => _startGame(context, 'hard'),
            ),
            const SizedBox(height: 12),
            _DifficultyCard(
              label: l10n.levelSelectExpert,
              icon: Icons.whatshot,
              color: Colors.deepPurple,
              onTap: () => _startGame(context, 'expert'),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, String difficulty) {
    Navigator.of(context).pushNamed(
      LevelListScreen.routeName,
      arguments: {'difficulty': difficulty},
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(width: 20),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
