class Sucursal {
  final String codigo;
  final String descripcion;

  Sucursal({required this.codigo, required this.descripcion});

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      codigo: json['cod_sucursal']?.toString() ?? '',
      descripcion: json['descripcion_sucursal'] ?? 'Sin nombre',
    );
  }
}