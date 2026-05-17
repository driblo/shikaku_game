import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/progress_service.dart';

final completionsProvider =
    FutureProvider.autoDispose.family<Map<int, int>, String>(
  (ref, difficulty) => ProgressService.getAllCompletions(difficulty),
);
