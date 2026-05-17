import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/board.dart';
import '../model/region.dart';
import '../services/puzzle_repository.dart';

enum GamePhase { loading, playing, won }

class GameState {
  final GamePhase phase;
  final Board? board;
  final int elapsedSeconds;
  final ({int r, int c})? dragAnchor;
  final ({int r, int c})? dragCurrent;

  const GameState({
    required this.phase,
    this.board,
    this.elapsedSeconds = 0,
    this.dragAnchor,
    this.dragCurrent,
  });

  GameState copyWith({
    GamePhase? phase,
    Board? board,
    int? elapsedSeconds,
    ({int r, int c})? dragAnchor,
    ({int r, int c})? dragCurrent,
    bool clearDrag = false,
  }) =>
      GameState(
        phase: phase ?? this.phase,
        board: board ?? this.board,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        dragAnchor: clearDrag ? null : (dragAnchor ?? this.dragAnchor),
        dragCurrent: clearDrag ? null : (dragCurrent ?? this.dragCurrent),
      );
}

class GameNotifier extends AutoDisposeNotifier<GameState> {
  Timer? _timer;

  @override
  GameState build() {
    ref.onDispose(() => _timer?.cancel());
    return const GameState(phase: GamePhase.loading);
  }

  Future<void> loadPuzzle(String difficulty, int index) async {
    state = const GameState(phase: GamePhase.loading);
    _timer?.cancel();
    final pack = await PuzzleRepository.loadPack(difficulty);
    final puzzle = pack.puzzles[index % pack.puzzles.length];
    state = GameState(phase: GamePhase.playing, board: Board(puzzle));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase == GamePhase.playing) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void onDragStart(int r, int c) {
    if (state.board == null || state.phase != GamePhase.playing) return;
    state = state.copyWith(
      dragAnchor: (r: r, c: c),
      dragCurrent: (r: r, c: c),
    );
  }

  void onDragUpdate(int r, int c) {
    if (state.dragAnchor == null) return;
    state = state.copyWith(dragCurrent: (r: r, c: c));
  }

  void onDragEnd() {
    final board = state.board;
    final anchor = state.dragAnchor;
    final current = state.dragCurrent;
    if (board == null || anchor == null || current == null) {
      state = state.copyWith(clearDrag: true);
      return;
    }
    final region = Region(
      r1: min(anchor.r, current.r),
      c1: min(anchor.c, current.c),
      r2: max(anchor.r, current.r),
      c2: max(anchor.c, current.c),
    );
    // Find the single clue inside the dragged region.
    int? clueIdx;
    for (var i = 0; i < board.puzzle.clues.length; i++) {
      final cl = board.puzzle.clues[i];
      if (region.contains(cl.r, cl.c)) {
        if (clueIdx != null) {
          clueIdx = null;
          break;
        }
        clueIdx = i;
      }
    }
    if (clueIdx != null) {
      board.placeRegion(clueIdx, region);
    }
    state = state.copyWith(board: board, clearDrag: true);
    if (board.isSolved) {
      _timer?.cancel();
      state = state.copyWith(phase: GamePhase.won);
    }
  }

  void undoLast() {
    final board = state.board;
    if (board == null || state.phase != GamePhase.playing) return;
    for (var i = board.regions.length - 1; i >= 0; i--) {
      if (board.regions[i] != null) {
        board.clearRegion(i);
        state = state.copyWith(board: board);
        return;
      }
    }
  }

  void resetBoard() {
    final board = state.board;
    if (board == null) return;
    for (var i = 0; i < board.regions.length; i++) {
      board.clearRegion(i);
    }
    state = GameState(
      phase: GamePhase.playing,
      board: board,
      elapsedSeconds: 0,
    );
    _startTimer();
  }

}

final gameProvider =
    AutoDisposeNotifierProvider<GameNotifier, GameState>(GameNotifier.new);
