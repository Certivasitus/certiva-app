import 'api_client.dart';

class CertivaApiService {
  static final CertivaApiService _instance = CertivaApiService._internal();
  factory CertivaApiService() => _instance;
  CertivaApiService._internal();

  static const String _endpointRegistro = '/app/registrar_cliente';

  /// Registra un nuevo cliente consumiendo el procedimiento [pr_crear_cuenta_json] en Oracle APEX.
  Future<Map<String, dynamic>> registrarCliente({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String cedula,
    required int prepaga,
    required String direccion,
    required String telefono,
  }) async {

    // Se eliminan caracteres no numéricos para cumplir con el tipo NUMBER(20) de Oracle
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^0-9]'), '');

    final body = {
      'email': email,
      'password': password,
      'nombre': nombre,
      'apellido': apellido,
      'autenticacion': 'CORREO', // Valor fijo exigido por la lógica de negocio en BD
      'cedula': cedula,
      'prepaga': prepaga,
      'direccion': direccion,
      'telefono': telefonoLimpio,
    };

    print('🚀 [CertivaApi] POST $_endpointRegistro | Body: $body');

    final response = await ApiClient.post(_endpointRegistro, body);

    if (response != null) {
      // Evaluación de la respuesta estructurada desde APEX
      if (response['status'] == 'success') {
        return {
          'success': true,
          'data': response,
          'message': 'Cliente registrado: ${response['nombre_cliente']}',
        };
      } else {
        // Captura de errores de validación de negocio (ej. correos duplicados - Error 400)
        return {
          'success': false,
          'error': response['mensaje'] ?? response['description'] ?? 'Error al registrar cliente',
          'code': response['codigo']?.toString() ?? 'API_ERROR',
        };
      }
    } else {
      // Fallo a nivel de red, timeout o error 500 no capturado
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor. Verifica tu conexión a internet e intenta de nuevo.',
        'code': 'CONNECTION_ERROR',
      };
    }
  }

  /// Obtiene la lista de prepagas activas.
  Future<List<Map<String, dynamic>>> getPrepagasActivas() async {
    final response = await ApiClient.get(_endpointRegistro);

    if (response != null && response['prepagas'] != null) {
      final List list = response['prepagas'];
      return list.cast<Map<String, dynamic>>();
    }

    return [];
  }
}