import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodel/game_viewmodel.dart';
import 'board_painter.dart';

class BoardWidget extends ConsumerWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final board = state.board;
    if (board == null) return const SizedBox.shrink();

    final rows = board.puzzle.rows;
    final cols = board.puzzle.cols;

    return LayoutBuilder(builder: (context, constraints) {
      final cellSize = min(
        constraints.maxWidth / cols,
        constraints.maxHeight / rows,
      );
      final boardW = cellSize * cols;
      final boardH = cellSize * rows;

      return Center(
        child: Container(
          width: boardW,
          height: boardH,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: GestureDetector(
            onPanStart: (d) {
              final r =
                  (d.localPosition.dy / cellSize).floor().clamp(0, rows - 1);
              final c =
                  (d.localPosition.dx / cellSize).floor().clamp(0, cols - 1);
              ref.read(gameProvider.notifier).onDragStart(r, c);
            },
            onPanUpdate: (d) {
              final r =
                  (d.localPosition.dy / cellSize).floor().clamp(0, rows - 1);
              final c =
                  (d.localPosition.dx / cellSize).floor().clamp(0, cols - 1);
              ref.read(gameProvider.notifier).onDragUpdate(r, c);
            },
            onPanEnd: (_) => ref.read(gameProvider.notifier).onDragEnd(),
            onPanCancel: () => ref.read(gameProvider.notifier).onDragEnd(),
            child: CustomPaint(
              painter: BoardPainter(
                board: board,
                dragAnchor: state.dragAnchor,
                dragCurrent: state.dragCurrent,
              ),
            ),
          ),
        ),
      );
    });
  }
}
