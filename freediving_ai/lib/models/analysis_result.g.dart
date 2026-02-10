// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnalysisResultAdapter extends TypeAdapter<AnalysisResult> {
  @override
  final int typeId = 1;

  @override
  AnalysisResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalysisResult(
      id: fields[0] as String,
      userId: fields[1] as String,
      discipline: fields[2] as String,
      videoPath: fields[3] as String,
      category: fields[4] as String,
      overallScore: fields[5] as double,
      categoryScores: (fields[6] as Map).cast<String, double>(),
      strengths: (fields[7] as List).cast<String>(),
      improvements: (fields[8] as List).cast<String>(),
      drillRecommendations: (fields[9] as List).cast<String>(),
      createdAt: fields[10] as DateTime,
      poseData: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AnalysisResult obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.discipline)
      ..writeByte(3)
      ..write(obj.videoPath)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.overallScore)
      ..writeByte(6)
      ..write(obj.categoryScores)
      ..writeByte(7)
      ..write(obj.strengths)
      ..writeByte(8)
      ..write(obj.improvements)
      ..writeByte(9)
      ..write(obj.drillRecommendations)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.poseData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
