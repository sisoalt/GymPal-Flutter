import 'package:hive/hive.dart';

part 'progress_model.g.dart';

@HiveType(typeId: 4)
class ProgressModel extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double weight;

  @HiveField(2)
  final String? photoPath; // Local path to the image file

  @HiveField(3)
  final String notes;

  ProgressModel({
    required this.date,
    required this.weight,
    this.photoPath,
    this.notes = '',
  });
}