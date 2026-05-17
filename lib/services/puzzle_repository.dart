import 'dart:convert';

import 'package:flutter/services.dart';

import '../model/puzzle.dart';

class PuzzleRepository {
  static final Map<String, PuzzlePack> _cache = {};

  static Future<PuzzlePack> loadPack(String difficulty) async {
    if (_cache.containsKey(difficulty)) return _cache[difficulty]!;
    final raw =
        await rootBundle.loadString('assets/puzzles/${difficulty}_pack.json');
    final pack =
        PuzzlePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cache[difficulty] = pack;
    return pack;
  }
}
