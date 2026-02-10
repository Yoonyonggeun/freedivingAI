// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingTemplateAdapter extends TypeAdapter<TrainingTemplate> {
  @override
  final int typeId = 3;

  @override
  TrainingTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingTemplate(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      rounds: fields[3] as int,
      holdTimes: (fields[4] as List).cast<int>(),
      restTimes: (fields[5] as List).cast<int>(),
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingTemplate obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.rounds)
      ..writeByte(4)
      ..write(obj.holdTimes)
      ..writeByte(5)
      ..write(obj.restTimes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
