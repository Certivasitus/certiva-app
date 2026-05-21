import '../services/api_client.dart';

class Prepaga {
  final String id;
  final String nombre;

  Prepaga({required this.id, required this.nombre});

  factory Prepaga.fromJson(Map<String, dynamic> json) {
    return Prepaga(
      id: json['cod_prepaga']?.toString() ?? '0',
      nombre: json['descripcion_prepaga'] ?? 'Sin descripción',
    );
  }
}

class PrepagaService {

  static bool idsMatch(String? a, String? b) {
    if (a == null || b == null) return false;
    final sa = a.trim();
    final sb = b.trim();
    if (sa == sb) return true;
    final ia = int.tryParse(sa);
    final ib = int.tryParse(sb);
    return ia != null && ib != null && ia == ib;
  }

  /// Incluye la prepaga ya asignada al cliente aunque no esté en get_prepagas del portal.
  static List<Prepaga> mergeAssignedPrepaga({
    required List<Prepaga> prepagas,
    String? assignedId,
    String? assignedNombre,
  }) {
    final id = assignedId?.trim();
    if (id == null || id.isEmpty) return prepagas;
    if (prepagas.any((p) => idsMatch(p.id, id))) return prepagas;

    final nombre = (assignedNombre != null && assignedNombre.trim().isNotEmpty)
        ? assignedNombre.trim()
        : 'Seguro médico asignado';

    return [...prepagas, Prepaga(id: id, nombre: nombre)];
  }

  static Prepaga? findById(List<Prepaga> prepagas, String? id) {
    if (id == null) return null;
    for (final p in prepagas) {
      if (idsMatch(p.id, id)) return p;
    }
    return null;
  }

  static Future<List<Prepaga>> getPrepagas() async {
    final responseData = await ApiClient.get('/app/get_prepagas');

    if (responseData != null && responseData is Map<String, dynamic>) {
      if (responseData.containsKey('prepagas')) {
        final List<dynamic> list = responseData['prepagas'];
        return list.map((item) => Prepaga.fromJson(item)).toList();
      }
    }

    return [];
  }
}