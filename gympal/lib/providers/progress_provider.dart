import 'package:flutter/material.dart';
import '../data/services/hive_service.dart';
import '../data/models/progress_model.dart';

class ProgressProvider extends ChangeNotifier {
  List<ProgressModel> _logs = [];

  // Settings Data
  double _heightCm = 175;
  double _targetWeight = 70;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  String _goalType = 'Lose Weight';

  // NEW: The exercise name to track for the Strength Record card
  String _strengthExercise = 'Bench Press';

  List<ProgressModel> get logs => _logs;
  double get heightCm => _heightCm;
  double get targetWeight => _targetWeight;
  DateTime get targetDate => _targetDate;
  String get goalType => _goalType;
  String get strengthExercise => _strengthExercise; // Getter

  // --- Derived Stats ---
  double get currentWeight {
    if (_logs.isNotEmpty) return _logs.first.weight;

    // If no logs, try to get weight from user profile
    final settings = HiveService.settingsBox;
    final userWeight = settings.get('user_weight');
    if (userWeight != null) return userWeight as double;

    // Indicate that current weight is not set by returning NaN
    return double.nan;
  }

  double get startingWeight {
    if (_logs.isNotEmpty) return _logs.last.weight;

    // If no logs, use current weight as starting weight
    return currentWeight;
  }

  double get totalChange {
    if (_logs.isEmpty) return 0.0;
    if (currentWeight.isNaN || startingWeight.isNaN) return 0.0;
    return (currentWeight - startingWeight);
  }

  double get weightLeft {
    if (currentWeight.isNaN) return double.nan;
    return (currentWeight - _targetWeight).abs();
  }

  double get bmi {
    if (_heightCm == 0 || currentWeight.isNaN) return 0.0;
    double heightM = _heightCm / 100;
    return currentWeight / (heightM * heightM);
  }

  Map<String, dynamic> get bmiCategory {
    final b = bmi;
    if (b < 18.5) return {'label': 'Underweight', 'color': Colors.blue};
    if (b < 25) return {'label': 'Normal', 'color': Colors.green};
    if (b < 30) return {'label': 'Overweight', 'color': Colors.orange};
    return {'label': 'Obese', 'color': Colors.red};
  }

  // --- Actions ---

  void loadLogs() {
    final box = HiveService.progressBox;
    _logs = box.values.toList().cast<ProgressModel>();
    _logs.sort((a, b) => b.date.compareTo(a.date));

    _loadSettings();
    notifyListeners();
  }

  void _loadSettings() {
    final settings = HiveService.settingsBox;
    _heightCm = settings.get('user_height') ?? 175.0;
    _targetWeight = settings.get('goal_weight') ?? 70.0;
    _targetDate = DateTime.parse(settings.get('goal_date') ??
        DateTime.now().add(const Duration(days: 90)).toIso8601String());
    _goalType = settings.get('goal_type') ?? 'Lose Weight';

    // Load preferred strength exercise (Default to Bench Press)
    _strengthExercise = settings.get('strength_exercise') ?? 'Bench Press';
  }

  // Update Goals
  Future<void> updateSettings(
      double height, double targetW, DateTime targetD, String type) async {
    final settings = HiveService.settingsBox;
    await settings.put('user_height', height);
    await settings.put('goal_weight', targetW);
    await settings.put('goal_date', targetD.toIso8601String());
    await settings.put('goal_type', type);

    _heightCm = height;
    _targetWeight = targetW;
    _targetDate = targetD;
    _goalType = type;
    notifyListeners();
  }

  // NEW: Update Strength Exercise Name
  Future<void> setStrengthExercise(String name) async {
    final settings = HiveService.settingsBox;
    await settings.put('strength_exercise', name);
    _strengthExercise = name;
    notifyListeners();
  }

  Future<void> addProgress(ProgressModel log) async {
    final box = HiveService.progressBox;
    await box.add(log);
    // Save the latest weight to settings so currentWeight reflects user's input
    final settings = HiveService.settingsBox;
    await settings.put('user_weight', log.weight);
    loadLogs();
  }

  // NEW: Edit Existing Log
  Future<void> editProgress(ProgressModel oldLog, double weight, String notes,
      String? photoPath, List<String>? photoPaths) async {
    // If your model fields are final, we must replace the entry:
    final newLog = ProgressModel(
      date: oldLog.date,
      weight: weight,
      notes: notes,
      photoPath: photoPath,
      photoPaths: photoPaths,
    );

    // Replace in Hive
    final box = HiveService.progressBox;
    final key = oldLog.key; // Get the key of the old object
    await box.put(key, newLog); // Overwrite at that key

    // Update stored current weight as well
    final settings = HiveService.settingsBox;
    await settings.put('user_weight', weight);

    loadLogs();
  }

  Future<void> deleteProgress(ProgressModel log) async {
    await log.delete();
    loadLogs();
  }
}
