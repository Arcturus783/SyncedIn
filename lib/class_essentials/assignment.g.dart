// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assignment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssignmentAdapter extends TypeAdapter<Assignment> {
  @override
  final int typeId = 0;

  @override
  Assignment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Assignment(
      title: fields[0] as String,
      type: fields[2] as String,
      dueDate: fields[1] as DateTime?,
      completed: fields[3] as bool,
      visible: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Assignment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.dueDate)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.visible);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssignmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
