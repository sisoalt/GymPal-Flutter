import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import '../models/food_log_model.dart'; // Updated Import
import '../models/progress_model.dart';

class HiveService {
  static const String userBoxName = 'userBox';
  static const String workoutBoxName = 'workoutBox';
  static const String calorieBoxName = 'calorieBox';
  static const String progressBoxName = 'progressBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(ExerciseModelAdapter());
    Hive.registerAdapter(WorkoutModelAdapter());
    Hive.registerAdapter(FoodLogModelAdapter()); // <--- UPDATED
    Hive.registerAdapter(ProgressModelAdapter());

    // Open Data Boxes
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<WorkoutModel>(workoutBoxName);
    await Hive.openBox<FoodLogModel>(calorieBoxName); // <--- UPDATED
    await Hive.openBox<ProgressModel>(progressBoxName);
    
    // Open Settings Box (Generic, not typed)
    await Hive.openBox(settingsBoxName); 
  }
  
  static Box<UserModel> get userBox => Hive.box<UserModel>(userBoxName);
  static Box<WorkoutModel> get workoutBox => Hive.box<WorkoutModel>(workoutBoxName);
  static Box<FoodLogModel> get calorieBox => Hive.box<FoodLogModel>(calorieBoxName); // <--- UPDATED
  static Box<ProgressModel> get progressBox => Hive.box<ProgressModel>(progressBoxName);
  
  // Getter for the generic settings box
  static Box get settingsBox => Hive.box(settingsBoxName);
}