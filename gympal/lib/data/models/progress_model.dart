import 'package:hive/hive.dart';

part 'progress_model.g.dart';

@HiveType(typeId: 4)
class ProgressModel extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double weight;

  @HiveField(2)
  final String? photoPath; // Keeping for backward compatibility

  @HiveField(3)
  final String notes;

  @HiveField(4)
  final List<String>? photoPaths; // Multiple photos support

  ProgressModel({
    required this.date,
    required this.weight,
    this.photoPath,
    this.notes = '',
    this.photoPaths,
  });
}