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
}