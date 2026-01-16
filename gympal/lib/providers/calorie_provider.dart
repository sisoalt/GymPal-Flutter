import 'package:flutter/material.dart';
import '../data/services/hive_service.dart';
import '../data/models/food_log_model.dart';

class CalorieProvider extends ChangeNotifier {
  List<FoodLogModel> _todayLogs = [];
  DateTime _selectedDate = DateTime.now();
  
  // --- Daily calorie goal (persisted in settingsBox) ---
  int _dailyGoal = 2500; 

  List<FoodLogModel> get todayLogs => _todayLogs;
  DateTime get selectedDate => _selectedDate;
  
  // --- ADDED THIS BACK ---
  int get dailyGoal => _dailyGoal; 

  CalorieProvider() {
    // Load persisted daily goal from settings if available
    try {
      final settings = HiveService.settingsBox;
      final saved = settings.get('daily_calorie_goal');
      if (saved != null && saved is int) {
        _dailyGoal = saved;
      }
    } catch (_) {
      // ignore if settings not available yet
    }
  }
  
  // Calculate total calories
  int get totalCalories => _todayLogs.fold(0, (sum, item) => sum + item.calories);

  void loadLogs(DateTime date) {
    _selectedDate = date;
    final box = HiveService.calorieBox;
    
    _todayLogs = box.values.where((log) {
      return log.date.year == date.year &&
             log.date.month == date.month &&
             log.date.day == date.day;
    }).toList();
    
    notifyListeners();
  }

  Future<void> addFoodLog(FoodLogModel log) async {
    final box = HiveService.calorieBox;
    await box.add(log);
    loadLogs(_selectedDate);
  }

  Future<void> editFoodLog(FoodLogModel oldLog, String newName, int newCals, String newType) async {
    oldLog.name = newName;
    oldLog.calories = newCals;
    oldLog.mealType = newType;
    await oldLog.save();
    loadLogs(_selectedDate);
  }

  Future<void> deleteFoodLog(FoodLogModel log) async {
    await log.delete();
    loadLogs(_selectedDate);
  }

  Future<void> clearDailyLogs() async {
    for (var log in _todayLogs) {
      await log.delete();
    }
    loadLogs(_selectedDate);
  }
  
  // Optional: Allow updating the goal
  void updateGoal(int newGoal) {
    _dailyGoal = newGoal;
    // Persist goal in settings box
    try {
      final settings = HiveService.settingsBox;
      settings.put('daily_calorie_goal', newGoal);
    } catch (_) {}
    notifyListeners();
  }

  /// Return total calories between [start] and [end] inclusive.
  int totalCaloriesForRange(DateTime start, DateTime end) {
    final box = HiveService.calorieBox;
    int sum = 0;
    for (var log in box.values) {
      final d = log.date;
      if (!d.isBefore(start) && !d.isAfter(end)) {
        sum += log.calories;
      }
    }
    return sum;
  }

  /// Convenience: total calories for the current week (Mon-Sun)
  int totalCaloriesThisWeek() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return totalCaloriesForRange(start, end);
  }
}