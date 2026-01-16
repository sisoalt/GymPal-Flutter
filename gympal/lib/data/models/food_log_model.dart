import 'package:hive/hive.dart';

part 'food_log_model.g.dart';

@HiveType(typeId: 3)
class FoodLogModel extends HiveObject {
  @HiveField(0)
  String name; // Changed from final to String to allow editing

  @HiveField(1)
  int calories; // Changed from final to int to allow editing

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String mealType; // Breakfast, Lunch, etc.

  FoodLogModel({
    required this.name,
    required this.calories,
    required this.date,
    required this.mealType,
  });
}