// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      nombres: fields[0] as String,
      apellidos: fields[1] as String,
      cedula: fields[2] as String,
      direccion: fields[3] as String,
      celular: fields[4] as String,
      email: fields[5] as String,
      seguro: fields[6] as String,
      password: fields[7] as String,
      idCliente: fields[8] as int?,
      ruc: fields[9] as String?,
      razonSocial: fields[10] as String?,
      sexo: fields[11] as String?,
      cliIdCliente: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.nombres)
      ..writeByte(1)
      ..write(obj.apellidos)
      ..writeByte(2)
      ..write(obj.cedula)
      ..writeByte(3)
      ..write(obj.direccion)
      ..writeByte(4)
      ..write(obj.celular)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.seguro)
      ..writeByte(7)
      ..write(obj.password)
      ..writeByte(8)
      ..write(obj.idCliente)
      ..writeByte(9)
      ..write(obj.ruc)
      ..writeByte(10)
      ..write(obj.razonSocial)
      ..writeByte(11)
      ..write(obj.sexo)
      ..writeByte(12)
      ..write(obj.cliIdCliente);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
