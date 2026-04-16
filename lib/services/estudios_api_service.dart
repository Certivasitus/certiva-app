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

  // Obtener Estudios
  static Future<List<Estudio>> getEstudiosCliente(
      int idCliente, {
        String? fecha,    // dd-MM-yy
        String? sucursal, // ID Sucursal
        String? estudio, // ID estudio
      }) async {

    String endpoint = '/app/estudio/resultados/$idCliente';

    List<String> params = [];
    if (fecha != null && fecha.isNotEmpty) params.add('fecha=$fecha');
    if (sucursal != null && sucursal.isNotEmpty) params.add('sucursal=$sucursal');
    if (estudio != null && estudio.isNotEmpty) params.add('estudio=$estudio');

    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }

    final response = await ApiClient.get(endpoint);

    if (response != null && response['estudios'] != null) {
      final List<dynamic> list = response['estudios'];
      return list.map((e) => Estudio.fromJson(e)).toList();
    }

    return [];
  }
}