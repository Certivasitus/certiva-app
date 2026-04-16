class Estudio {
  final int codSolicitud;
  final String analisis;       // Nombre visible (ej: Hemograma)
  final String codAnalisis;    // ID para el filtro (ej: 105) <--- NUEVO
  final String fechaSolicitud;
  final String codSucursal;
  final String nombreSucursal;
  final int? codFirma;

  Estudio({
    required this.codSolicitud,
    required this.analisis,
    required this.codAnalisis,
    required this.fechaSolicitud,
    required this.codSucursal,
    required this.nombreSucursal,
    this.codFirma,
  });

  factory Estudio.fromJson(Map<String, dynamic> json) {
    return Estudio(
      codSolicitud: json['cod_solicitud'] is int ? json['cod_solicitud'] : int.parse(json['cod_solicitud'].toString()),
      analisis: json['analisis'] ?? 'Estudio sin nombre',
      codAnalisis: json['cod_analisis']?.toString() ?? '',
      fechaSolicitud: json['fecha_solicitud'] ?? '',
      codSucursal: json['cod_sucursal']?.toString() ?? '',
      nombreSucursal: json['nombre_sucursal'] ?? '',
      codFirma: json['cod_firma'] != null ? (json['cod_firma'] is int ? json['cod_firma'] : int.parse(json['cod_firma'].toString())) : null,
    );
  }
}