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