import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../model/board.dart';
import '../../model/region.dart';

// Distinct fill colors for placed regions, cycling by clue index.
const _fillColors = [
  Color(0x553B6CD8),
  Color(0x55D83B6C),
  Color(0x556CB83B),
  Color(0x55D8902F),
  Color(0x559C3BD8),
  Color(0x553BD8C8),
  Color(0x55C8D83B),
  Color(0x55D83B9C),
];

const _borderColors = [
  Color(0xFF3B6CD8),
  Color(0xFFD83B6C),
  Color(0xFF6CB83B),
  Color(0xFFD8902F),
  Color(0xFF9C3BD8),
  Color(0xFF3BD8C8),
  Color(0xFFC8D83B),
  Color(0xFFD83B9C),
];

class BoardPainter extends CustomPainter {
  final Board board;
  final ({int r, int c})? dragAnchor;
  final ({int r, int c})? dragCurrent;

  const BoardPainter({
    required this.board,
    this.dragAnchor,
    this.dragCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = board.puzzle.rows;
    final cols = board.puzzle.cols;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // White background so clues are always legible regardless of system theme.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    _drawRegions(canvas, cellW, cellH);
    _drawDragPreview(canvas, cellW, cellH, rows, cols);
    _drawGrid(canvas, size, cellW, cellH, rows, cols);
    _drawClues(canvas, cellW, cellH);
  }

  void _drawRegions(Canvas canvas, double cellW, double cellH) {
    for (var i = 0; i < board.regions.length; i++) {
      final region = board.regions[i];
      if (region == null) continue;
      final rect = _regionRect(region, cellW, cellH);
      final fill = _fillColors[i % _fillColors.length];
      final border = _borderColors[i % _borderColors.length];
      canvas.drawRect(rect, Paint()..color = fill);
      canvas.drawRect(
        rect,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _drawDragPreview(
      Canvas canvas, double cellW, double cellH, int rows, int cols) {
    final anchor = dragAnchor;
    final current = dragCurrent;
    if (anchor == null || current == null) return;
    final region = Region(
      r1: min(anchor.r, current.r),
      c1: min(anchor.c, current.c),
      r2: max(anchor.r, current.r),
      c2: max(anchor.c, current.c),
    );
    final rect = _regionRect(region, cellW, cellH);
    canvas.drawRect(rect, Paint()..color = const Color(0x55FFC107));
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawGrid(Canvas canvas, Size size, double cellW, double cellH,
      int rows, int cols) {
    final innerPaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 0.8;
    for (var r = 1; r < rows; r++) {
      canvas.drawLine(Offset(0, r * cellH), Offset(size.width, r * cellH), innerPaint);
    }
    for (var c = 1; c < cols; c++) {
      canvas.drawLine(Offset(c * cellW, 0), Offset(c * cellW, size.height), innerPaint);
    }
    // Outer border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = const Color(0xFF333333)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawClues(Canvas canvas, double cellW, double cellH) {
    for (final clue in board.puzzle.clues) {
      final center =
          Offset((clue.c + 0.5) * cellW, (clue.r + 0.5) * cellH);
      final fontSize = min(cellW, cellH) * 0.44;
      final tp = TextPainter(
        text: TextSpan(
          text: '${clue.v}',
          style: TextStyle(
            color: const Color(0xFF111111),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  Rect _regionRect(Region region, double cellW, double cellH) =>
      Rect.fromLTWH(
        region.c1 * cellW,
        region.r1 * cellH,
        (region.c2 - region.c1 + 1) * cellW,
        (region.r2 - region.r1 + 1) * cellH,
      );

  @override
  bool shouldRepaint(BoardPainter old) => true;
}
