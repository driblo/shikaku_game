import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodel/completions_provider.dart';
import 'game_screen.dart';

class LevelListScreen extends ConsumerWidget {
  const LevelListScreen({required this.difficulty, super.key});

  final String difficulty;

  static const routeName = '/level-list';

  String _difficultyLabel() {
    return switch (difficulty) {
      'easy' => 'Easy',
      'medium' => 'Medium',
      'hard' => 'Hard',
      'expert' => 'Expert',
      _ => difficulty,
    };
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return m > 0 ? '${m}m ${s.toString().padLeft(2, '0')}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionsAsync = ref.watch(completionsProvider(difficulty));

    return Scaffold(
      appBar: AppBar(title: Text(_difficultyLabel())),
      body: completionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (completions) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: 50,
          itemBuilder: (context, i) {
            final done = completions[i];
            final isDone = done != null;
            final isLocked = i != 0 && !completions.containsKey(i - 1);

            return _LevelCard(
              number: i + 1,
              isDone: isDone,
              isLocked: isLocked,
              timeLabel: isDone ? _formatTime(done) : null,
              onTap: isLocked
                  ? null
                  : () async {
                      await Navigator.of(context).pushNamed(
                        GameScreen.routeName,
                        arguments: {'difficulty': difficulty, 'index': i},
                      );
                      ref.invalidate(completionsProvider(difficulty));
                    },
            );
          },
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.number,
    required this.isDone,
    required this.isLocked,
    this.timeLabel,
    this.onTap,
  });

  final int number;
  final bool isDone;
  final bool isLocked;
  final String? timeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bgColor;
    final Color fgColor;
    if (isLocked) {
      bgColor = theme.colorScheme.surfaceContainerLowest;
      fgColor = theme.colorScheme.onSurface.withValues(alpha: 0.35);
    } else if (isDone) {
      bgColor = Colors.green.shade600;
      fgColor = Colors.white;
    } else {
      bgColor = theme.colorScheme.surfaceContainerHighest;
      fgColor = theme.colorScheme.onSurface;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLocked)
                Icon(Icons.lock, color: fgColor, size: 16)
              else if (isDone)
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
              Text(
                '$number',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (timeLabel != null)
                Text(
                  timeLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fgColor.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
