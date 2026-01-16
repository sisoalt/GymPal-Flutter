import 'package:hive/hive.dart';

part 'exercise_model.g.dart'; // This will be generated

@HiveType(typeId: 2) // Unique ID for this model
class ExerciseModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String sets;

  @HiveField(2)
  final String reps;

  @HiveField(3)
  final String weight;

  ExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });
}