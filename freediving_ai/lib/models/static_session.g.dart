// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'static_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StaticSessionAdapter extends TypeAdapter<StaticSession> {
  @override
  final int typeId = 2;

  @override
  StaticSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StaticSession(
      id: fields[0] as String,
      userId: fields[1] as String,
      tableType: fields[2] as String,
      rounds: fields[3] as int,
      holdTimes: (fields[4] as List).cast<int>(),
      restTimes: (fields[5] as List).cast<int>(),
      completedHoldTimes: (fields[6] as List).cast<int>(),
      createdAt: fields[7] as DateTime,
      completedAt: fields[8] as DateTime?,
      isCompleted: fields[9] as bool,
      completedRounds: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StaticSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.tableType)
      ..writeByte(3)
      ..write(obj.rounds)
      ..writeByte(4)
      ..write(obj.holdTimes)
      ..writeByte(5)
      ..write(obj.restTimes)
      ..writeByte(6)
      ..write(obj.completedHoldTimes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.completedRounds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
