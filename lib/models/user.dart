import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String nombres;

  @HiveField(1)
  String apellidos;

  @HiveField(2)
  String cedula;

  @HiveField(3)
  String direccion;

  @HiveField(4)
  String celular;

  @HiveField(5)
  String email;

  @HiveField(6)
  String seguro;

  @HiveField(7)
  String password;

  @HiveField(8)
  int? idCliente; // ID del cliente en la API

  @HiveField(9)
  String? ruc; // RUC de la persona

  @HiveField(10)
  String? razonSocial; // Razón social

  @HiveField(11)
  String? sexo; // 1 = MASCULINO, 2 = FEMENINO

  /// Nombre de la prepaga (solo en memoria; no persiste en Hive).
  String? seguroNombre;

  /// cli_id_cliente para get_cliente (solo en memoria).
  int? cliIdCliente;

  User({
    required this.nombres,
    required this.apellidos,
    required this.cedula,
    required this.direccion,
    required this.celular,
    required this.email,
    required this.seguro,
    required this.password,
    this.idCliente,
    this.ruc,
    this.razonSocial,
    this.sexo,
    this.seguroNombre,
    this.cliIdCliente,
  });

  String get nombreCompleto => '$nombres $apellidos';

  Map<String, dynamic> toMap() {
    return {
      'nombres': nombres,
      'apellidos': apellidos,
      'cedula': cedula,
      'direccion': direccion,
      'celular': celular,
      'email': email,
      'seguro': seguro,
      'password': password,
      'idCliente': idCliente,
      'ruc': ruc,
      'razonSocial': razonSocial,
      'sexo': sexo,
      'seguroNombre': seguroNombre,
      'cliIdCliente': cliIdCliente,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      cedula: map['cedula'] ?? '',
      direccion: map['direccion'] ?? '',
      celular: map['celular'] ?? '',
      email: map['email'] ?? '',
      seguro: map['seguro'] ?? '',
      password: map['password'] ?? '',
      idCliente: map['idCliente'],
      ruc: map['ruc'],
      razonSocial: map['razonSocial'],
      sexo: map['sexo'],
      seguroNombre: map['seguroNombre'],
      cliIdCliente: map['cliIdCliente'],
    );
  }
} 