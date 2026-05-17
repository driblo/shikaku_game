import 'puzzle.dart';
import 'region.dart';

class Board {
  final Puzzle puzzle;
  final List<Region?> regions;
  final List<int> ownership;

  Board(this.puzzle)
      : regions = List.filled(puzzle.clues.length, null),
        ownership = List.filled(puzzle.rows * puzzle.cols, -1);

  int _idx(int r, int c) => r * puzzle.cols + c;

  bool placeRegion(int clueIdx, Region region) {
    final clue = puzzle.clues[clueIdx];
    if (!region.contains(clue.r, clue.c)) return false;
    if (region.area != clue.v) return false;
    if (region.r1 < 0 || region.r2 >= puzzle.rows) return false;
    if (region.c1 < 0 || region.c2 >= puzzle.cols) return false;
    for (var i = 0; i < regions.length; i++) {
      if (i == clueIdx) continue;
      if (regions[i] != null && regions[i]!.overlaps(region)) return false;
    }
    for (var i = 0; i < puzzle.clues.length; i++) {
      if (i == clueIdx) continue;
      final other = puzzle.clues[i];
      if (region.contains(other.r, other.c)) return false;
    }
    clearRegion(clueIdx);
    regions[clueIdx] = region;
    for (var r = region.r1; r <= region.r2; r++) {
      for (var c = region.c1; c <= region.c2; c++) {
        ownership[_idx(r, c)] = clueIdx;
      }
    }
    return true;
  }

  void clearRegion(int clueIdx) {
    final old = regions[clueIdx];
    if (old == null) return;
    for (var r = old.r1; r <= old.r2; r++) {
      for (var c = old.c1; c <= old.c2; c++) {
        ownership[_idx(r, c)] = -1;
      }
    }
    regions[clueIdx] = null;
  }

  bool get isSolved =>
      regions.every((r) => r != null) && ownership.every((o) => o != -1);

  int ownerAt(int r, int c) => ownership[_idx(r, c)];
}
