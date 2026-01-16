import 'package:hive/hive.dart';
import 'exercise_model.dart';

part 'workout_model.g.dart';

@HiveType(typeId: 1)
class WorkoutModel extends HiveObject {
  @HiveField(0)
  String name; // Can be used for specific notes or sub-name

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  List<ExerciseModel> exercises;

  @HiveField(3)
  String duration;

  @HiveField(4) // <--- NEW FIELD
  String category;

  @HiveField(5)
  String shortNote;

  WorkoutModel({
    required this.name,
    required this.date,
    required this.exercises,
    this.duration = "0",
    this.category = "General", // Default value
    this.shortNote = "",
  });
}