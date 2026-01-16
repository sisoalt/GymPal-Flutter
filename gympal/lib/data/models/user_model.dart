import 'package:hive/hive.dart';

part 'user_model.g.dart'; // This file will be generated automatically

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String username; // Used for login

  @HiveField(1)
  String password; // Simple local password

  @HiveField(2)
  String fullName;

  @HiveField(3)
  int age;

  @HiveField(4)
  String gender;

  @HiveField(5)
  double? height; // in cm

  @HiveField(6)
  double? weight; // in kg
  @HiveField(7)
  String? profileImagePath;

  UserModel({
    required this.username,
    required this.password,
    required this.fullName,
    required this.age,
    required this.gender,
    this.height,
    this.weight,
    this.profileImagePath,
  });

  // Calculate BMI
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      return weight! / ((height! / 100) * (height! / 100));
    }
    return null;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'N/A';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }
}
