import 'api_client.dart';

class CertivaApiService {
  static final CertivaApiService _instance = CertivaApiService._internal();
  factory CertivaApiService() => _instance;
  CertivaApiService._internal();

  static const String _endpointRegistro = '/app/registrar_cliente';
  static const String _endpointVerificar = '/app/auth/verificar_codigo';
  static const String _endpointReenviar =
      '/app/auth/reenviar_codigo_verificacion';

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
      'autenticacion':
          'CORREO', // Valor fijo exigido por la lógica de negocio en BD
      'cedula': cedula,
      'prepaga': prepaga,
      'direccion': direccion,
      'telefono': telefonoLimpio,
    };

    print('🚀 [CertivaApi] POST $_endpointRegistro | Body: $body');

    final response = await ApiClient.post(_endpointRegistro, body);

    if (response != null) {
      final requiresVerification = response['requires_verification'] == true;
      if (response['status'] == 'success' || requiresVerification) {
        return {
          'success': true,
          'status': requiresVerification ? 'requires_verification' : 'success',
          'data': response,
          'message': response['mensaje'] ?? 'Registro completado.',
        };
      } else {
        return {
          'success': false,
          'error':
              response['mensaje'] ??
              response['message'] ??
              response['description'] ??
              'Error al registrar cliente',
          'code':
              response['codigo']?.toString() ??
              response['code']?.toString() ??
              'API_ERROR',
        };
      }
    } else {
      return {
        'success': false,
        'error': 'No se pudo conectar con el servidor.',
        'code': 'CONNECTION_ERROR',
      };
    }
  }

  /// Verifica el código OTP enviado al correo.
  Future<Map<String, dynamic>> verificarCodigo(
    String email,
    String codigo,
  ) async {
    final body = {'email': email, 'codigo': codigo};

    print('🚀 [CertivaApi] POST $_endpointVerificar | Body: $body');
    final response = await ApiClient.post(_endpointVerificar, body);

    if (response != null && response['status'] == 'success') {
      return {
        'success': true,
        'message': response['mensaje'] ?? 'Código verificado correctamente.',
      };
    } else {
      return {
        'success': false,
        'message': response?['mensaje'] ?? 'Código incorrecto o expirado.',
      };
    }
  }

  /// Solicita el reenvío del código de verificación.
  Future<Map<String, dynamic>> reenviarCodigo(String email) async {
    final body = {'email': email};

    print('🚀 [CertivaApi] POST $_endpointReenviar | Body: $body');
    final response = await ApiClient.post(_endpointReenviar, body);

    if (response != null && response['status'] == 'success') {
      return {
        'success': true,
        'message': response['mensaje'] ?? 'Nuevo código enviado.',
      };
    } else {
      return {
        'success': false,
        'message': response?['mensaje'] ?? 'Error al reenviar el código.',
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
