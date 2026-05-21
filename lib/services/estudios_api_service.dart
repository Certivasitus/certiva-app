import '../services/api_client.dart';
import '../models/estudio_model.dart';
import '../models/sucursal_model.dart';

class EstudiosApiService {

  // Obtener Sucursales
  static Future<List<Sucursal>> getSucursales() async {
    final response = await ApiClient.get('/app/get_sucursales');

    if (response != null && response['sucursales'] != null) {
      final List<dynamic> list = response['sucursales'];
      return list.map((e) => Sucursal.fromJson(e)).toList();
    }
    return [];
  }

  // Obtener resultados recientes (filtro opcional: sucursal)
  static Future<List<Estudio>> getEstudiosCliente(
    int idCliente, {
    String? sucursal,
  }) async {
    String endpoint = '/app/estudio/resultados/$idCliente';

    if (sucursal != null && sucursal.isNotEmpty) {
      endpoint += '?sucursal=$sucursal';
    }

    final response = await ApiClient.get(endpoint);

    if (response != null && response['estudios'] != null) {
      final List<dynamic> list = response['estudios'];
      return list.map((e) => Estudio.fromJson(e)).toList();
    }

    return [];
  }
}