import 'package:flutter/material.dart';

class Consultation {
  final String id;
  final String specialty;
  final String doctor;
  final String branch;

  /// Fecha formateada para mostrar en la UI (ej: "28/07/2025")
  final String date;

  final String time;

  /// Estados esperados: 'scheduled', 'completed', 'cancelled', 'pending'
  final String status;

  final String? notes;
  final DateTime createdAt;

  /// Fecha cruda de la API (YYYY-MM-DD) útil para validaciones de lógica (ej: regla de 6 horas)
  final String? fechaOriginal;

  Consultation({
    required this.id,
    required this.specialty,
    required this.doctor,
    required this.branch,
    required this.date,
    required this.time,
    required this.status,
    this.notes,
    required this.createdAt,
    this.fechaOriginal,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id']?.toString() ?? '',
      specialty: json['specialty'] ?? '',
      doctor: json['doctor'] ?? '',
      branch: json['branch'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'scheduled',
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      fechaOriginal: json['fechaOriginal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'specialty': specialty,
      'doctor': doctor,
      'branch': branch,
      'date': date,
      'time': time,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'fechaOriginal': fechaOriginal,
    };
  }

  // CopyWith para inmutabilidad
  Consultation copyWith({
    String? id,
    String? specialty,
    String? doctor,
    String? branch,
    String? date,
    String? time,
    String? status,
    String? notes,
    DateTime? createdAt,
    String? fechaOriginal,
  }) {
    return Consultation(
      id: id ?? this.id,
      specialty: specialty ?? this.specialty,
      doctor: doctor ?? this.doctor,
      branch: branch ?? this.branch,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      fechaOriginal: fechaOriginal ?? this.fechaOriginal,
    );
  }

  /// Convierte la fecha original a DateTime para poder ordenar listas cronológicamente
  DateTime? get dateTimeObject {
    if (fechaOriginal == null) return null;
    try {
      return DateTime.parse(fechaOriginal!);
    } catch (_) {
      return null;
    }
  }

  String get statusText {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'reservado':
        return 'Agendada';
      case 'completed':
      case 'cerrado':
        return 'Completada';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelada';
      case 'pending':
      case 'pendiente':
        return 'Pendiente';
      default:
        return 'Desconocido';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'reservado':
        return const Color(0xFF09D5D6);
      case 'completed':
      case 'cerrado':
        return Colors.green;
      case 'cancelled':
      case 'cancelado':
        return Colors.red;
      case 'pending':
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}