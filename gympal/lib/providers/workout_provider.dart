import 'package:flutter/material.dart';
import '../data/services/hive_service.dart';
import '../data/models/workout_model.dart';

class WorkoutProvider extends ChangeNotifier {
  List<WorkoutModel> _workouts = [];

  List<WorkoutModel> get workouts => _workouts;

  // 1. Load & Sort Workouts (Newest First)
  void loadWorkouts() {
    final box = HiveService.workoutBox;
    _workouts = box.values.toList().cast<WorkoutModel>();
    
    // Sort by Date Descending (Newest first)
    _workouts.sort((a, b) => b.date.compareTo(a.date));
    
    notifyListeners();
  }

  // 2. Add Workout
  Future<void> addWorkout(WorkoutModel workout) async {
    final box = HiveService.workoutBox;
    await box.add(workout);
    loadWorkouts();
  }

  // 3. Edit Logic (Update existing Hive Object)
  Future<void> editWorkout(WorkoutModel oldWorkout, WorkoutModel updatedData) async {
    // HiveObjects have a .save() method, but we manually update fields here
    oldWorkout.name = updatedData.name;
    oldWorkout.category = updatedData.category;
    oldWorkout.date = updatedData.date;
    oldWorkout.exercises = updatedData.exercises; // Replaces the list
    oldWorkout.duration = updatedData.duration;
    // persist short note
    oldWorkout.shortNote = updatedData.shortNote;
    
    await oldWorkout.save(); // Persists changes to Hive
    loadWorkouts();
  }

  // 4. Delete Workout
  Future<void> deleteWorkout(WorkoutModel workout) async {
    await workout.delete();
    loadWorkouts();
  }

  /// NEW: Count of workouts and exercises for each day in a range
  Map<DateTime, Map<String, int>> getWorkoutStatsForRange(DateTime start, DateTime end) {
    final Map<DateTime, Map<String, int>> stats = {};

    // Initialize with 0s
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final date = start.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      stats[dateKey] = {'workouts': 0, 'exercises': 0};
    }

    for (var w in _workouts) {
      final d = w.date;
      final dateKey = DateTime(d.year, d.month, d.day);
      if (stats.containsKey(dateKey)) {
        stats[dateKey]!['workouts'] = (stats[dateKey]!['workouts'] ?? 0) + 1;
        stats[dateKey]!['exercises'] = (stats[dateKey]!['exercises'] ?? 0) + w.exercises.length;
      }
    }

    return stats;
  }
}