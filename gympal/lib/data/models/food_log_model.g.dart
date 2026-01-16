// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodLogModelAdapter extends TypeAdapter<FoodLogModel> {
  @override
  final int typeId = 3;

  @override
  FoodLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodLogModel(
      name: fields[0] as String,
      calories: fields[1] as int,
      date: fields[2] as DateTime,
      mealType: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FoodLogModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.calories)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.mealType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
