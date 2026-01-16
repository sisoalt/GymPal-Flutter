// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutModelAdapter extends TypeAdapter<WorkoutModel> {
  @override
  final int typeId = 1;

  @override
  WorkoutModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutModel(
      name: fields[0] as String,
      date: fields[1] as DateTime,
      exercises: (fields[2] as List).cast<ExerciseModel>(),
      duration: fields[3] as String,
      category: fields[4] as String,
      shortNote: fields[5] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.exercises)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.shortNote);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
