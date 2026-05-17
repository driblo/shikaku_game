import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static String _key(String difficulty, int index) =>
      'progress_${difficulty}_$index';

  static Future<int?> getCompletion(String difficulty, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_key(difficulty, index));
    return v;
  }

  static Future<void> saveCompletion(
      String difficulty, int index, int elapsedSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(difficulty, index);
    final existing = prefs.getInt(key);
    if (existing == null || elapsedSeconds < existing) {
      await prefs.setInt(key, elapsedSeconds);
    }
  }

  static Future<Map<int, int>> getAllCompletions(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, int>{};
    for (var i = 0; i < 50; i++) {
      final v = prefs.getInt(_key(difficulty, i));
      if (v != null) result[i] = v;
    }
    return result;
  }
}
