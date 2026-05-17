class Clue {
  final int r, c, v;
  const Clue({required this.r, required this.c, required this.v});

  factory Clue.fromJson(Map<String, dynamic> j) =>
      Clue(r: j['r'] as int, c: j['c'] as int, v: j['v'] as int);
}

class Puzzle {
  final String id;
  final int rows, cols, parSeconds;
  final List<Clue> clues;

  const Puzzle({
    required this.id,
    required this.rows,
    required this.cols,
    required this.parSeconds,
    required this.clues,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) => Puzzle(
        id: j['id'] as String,
        rows: j['rows'] as int,
        cols: j['cols'] as int,
        parSeconds: j['parSeconds'] as int,
        clues: (j['clues'] as List)
            .map((e) => Clue.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PuzzlePack {
  final String packId, difficulty;
  final List<Puzzle> puzzles;

  const PuzzlePack({
    required this.packId,
    required this.difficulty,
    required this.puzzles,
  });

  factory PuzzlePack.fromJson(Map<String, dynamic> j) => PuzzlePack(
        packId: j['packId'] as String,
        difficulty: j['difficulty'] as String,
        puzzles: (j['puzzles'] as List)
            .map((e) => Puzzle.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
