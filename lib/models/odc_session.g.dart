// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'odc_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ODCSessionAdapter extends TypeAdapter<ODCSession> {
  @override
  final int typeId = 0;

  @override
  ODCSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ODCSession(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      checkInTime: fields[2] as DateTime?,
      checkOutTime: fields[3] as DateTime?,
      breaks: (fields[4] as List).cast<BreakSession>(),
      totalODCMinutes: fields[5] as int,
      totalBreakMinutes: fields[6] as int,
      isActive: fields[7] as bool,
      isOnBreak: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ODCSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.checkInTime)
      ..writeByte(3)
      ..write(obj.checkOutTime)
      ..writeByte(4)
      ..write(obj.breaks)
      ..writeByte(5)
      ..write(obj.totalODCMinutes)
      ..writeByte(6)
      ..write(obj.totalBreakMinutes)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.isOnBreak);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ODCSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BreakSessionAdapter extends TypeAdapter<BreakSession> {
  @override
  final int typeId = 1;

  @override
  BreakSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BreakSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime?,
      endTime: fields[2] as DateTime?,
      durationMinutes: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BreakSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.durationMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BreakSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimelineEntryAdapter extends TypeAdapter<TimelineEntry> {
  @override
  final int typeId = 2;

  @override
  TimelineEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimelineEntry(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      type: fields[2] as TimelineEntryType,
      description: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TimelineEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimelineEntryTypeAdapter extends TypeAdapter<TimelineEntryType> {
  @override
  final int typeId = 3;

  @override
  TimelineEntryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TimelineEntryType.checkIn;
      case 1:
        return TimelineEntryType.checkOut;
      case 2:
        return TimelineEntryType.breakStart;
      case 3:
        return TimelineEntryType.breakEnd;
      default:
        return TimelineEntryType.checkIn;
    }
  }

  @override
  void write(BinaryWriter writer, TimelineEntryType obj) {
    switch (obj) {
      case TimelineEntryType.checkIn:
        writer.writeByte(0);
        break;
      case TimelineEntryType.checkOut:
        writer.writeByte(1);
        break;
      case TimelineEntryType.breakStart:
        writer.writeByte(2);
        break;
      case TimelineEntryType.breakEnd:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineEntryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
