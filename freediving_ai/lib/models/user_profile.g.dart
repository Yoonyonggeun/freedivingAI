// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      diverLevel: fields[2] as String,
      competitionLevel: fields[3] as String,
      mainDisciplines: (fields[4] as List).cast<String>(),
      personalBests: (fields[5] as Map).cast<String, double>(),
      trainingGoals: (fields[6] as List).cast<String>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      provisionalLevel: fields[9] as int?,
      officialLevel: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.diverLevel)
      ..writeByte(3)
      ..write(obj.competitionLevel)
      ..writeByte(4)
      ..write(obj.mainDisciplines)
      ..writeByte(5)
      ..write(obj.personalBests)
      ..writeByte(6)
      ..write(obj.trainingGoals)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.provisionalLevel)
      ..writeByte(10)
      ..write(obj.officialLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
