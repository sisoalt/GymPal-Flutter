import 'hive_service.dart';
import '../exercise_library.dart';

class ExerciseLibraryService {
  static const _key = 'exercise_library';

  /// Loads the exercise library from settings or returns the default map.
  static Map<String, List<String>> loadLibrary() {
    final box = HiveService.settingsBox;
    final raw = box.get(_key);
    if (raw is Map) {
      final Map<String, List<String>> out = {};
      raw.forEach((k, v) {
        try {
          out[k.toString()] = (v as List).cast<String>().toList();
        } catch (_) {
          out[k.toString()] = [];
        }
      });
      return out;
    }

    // Fallback to builtin defaults
    return Map<String, List<String>>.from(exerciseLibrary);
  }

  /// Saves the given library map to settings.
  static Future<void> saveLibrary(Map<String, List<String>> lib) async {
    final box = HiveService.settingsBox;
    // Convert to a simple Map<String, List<String>> (safe types)
    final safe = <String, List<String>>{};
    lib.forEach((k, v) => safe[k] = List<String>.from(v));
    await box.put(_key, safe);
  }
}
