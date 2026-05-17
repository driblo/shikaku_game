import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/progress_service.dart';
import '../../viewmodel/game_viewmodel.dart';
import '../board/board_widget.dart';
import 'main_menu_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    required this.difficulty,
    required this.index,
    super.key,
  });

  final String difficulty;
  final int index;

  static const routeName = '/game';

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(gameProvider.notifier).loadPuzzle(widget.difficulty, widget.index));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen<GameState>(gameProvider, (prev, next) {
      if (next.phase == GamePhase.won && prev?.phase != GamePhase.won) {
        ProgressService.saveCompletion(
            widget.difficulty, widget.index, next.elapsedSeconds);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showWinDialog(context, l10n, next.elapsedSeconds);
        });
      }
    });

    final state = ref.watch(gameProvider);

    return Scaffold(
      appBar: AppBar(
        title: _TimerTitle(state: state, l10n: l10n),
        actions: [
          if (state.phase == GamePhase.playing) ...[
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: l10n.gameUndo,
              onPressed: () => ref.read(gameProvider.notifier).undoLast(),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.gameReset,
              onPressed: () => ref.read(gameProvider.notifier).resetBoard(),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: switch (state.phase) {
          GamePhase.loading =>
            const Center(child: CircularProgressIndicator()),
          GamePhase.playing || GamePhase.won => const Padding(
              padding: EdgeInsets.all(16),
              child: BoardWidget(),
            ),
        },
      ),
    );
  }

  void _showWinDialog(
      BuildContext context, AppLocalizations l10n, int elapsedSeconds) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(l10n.gameWon),
        content: Text(l10n.gameTime(elapsedSeconds)),
        actions: [
          if (widget.index < 49)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed(
                  GameScreen.routeName,
                  arguments: {
                    'difficulty': widget.difficulty,
                    'index': widget.index + 1,
                  },
                );
              },
              child: Text(l10n.gameNext),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).popUntil(
                  (route) => route.settings.name == MainMenuScreen.routeName);
            },
            child: Text(l10n.gameMenu),
          ),
        ],
      ),
    );
  }
}

class _TimerTitle extends StatelessWidget {
  const _TimerTitle({required this.state, required this.l10n});
  final GameState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (state.board == null) return const Text('Shikaku');
    final id = state.board!.puzzle.id.toUpperCase();
    final timeStr = l10n.gameTime(state.elapsedSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(id, style: Theme.of(context).textTheme.titleMedium),
        Text(timeStr,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }
}
