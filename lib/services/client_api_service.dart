import '../models/user.dart' as app_user;
import 'user_service.dart';
import 'api_client.dart';
import 'client_load_result.dart';

class ClientApiService {

  /// Convierte id_cliente de la API (int, double o string) a int.
  static int? parseIdCliente(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  static String _extractApiMessage(Map<String, dynamic>? data) {
    if (data == null) return 'sin respuesta del servidor';
    return data['descripcion']?.toString() ??
        data['mensaje']?.toString() ??
        data['message']?.toString() ??
        data['description']?.toString() ??
        data.toString();
  }

  static app_user.User? _mapClienteData(
    Map<String, dynamic> clienteData,
    int idClienteFallback,
  ) {
    return app_user.User(
      nombres: clienteData['nombre'] ?? '',
      apellidos: clienteData['apellido'] ?? '',
      cedula: clienteData['cedula']?.toString() ?? '',
      direccion: clienteData['direccion'] ?? '',
      celular: clienteData['telefono'] ?? '',
      email: clienteData['email'] ?? '',
      seguro: clienteData['prepaga']?.toString() ?? '',
      password: '',
      // id_cliente en JSON = PK ec_cliente (put_modificar_usuario); cli_id en URL de get_cliente
      idCliente: parseIdCliente(clienteData['id_cliente']) ?? idClienteFallback,
      ruc: clienteData['ruc']?.toString(),
      razonSocial: clienteData['razon_social']?.toString(),
      sexo: clienteData['sex_id_sexo']?.toString(),
    );
  }

  static bool _isMissingPrepagaError(ClientLoadResult result) {
    final detail = result.failureDetail?.toLowerCase() ?? '';
    return detail.contains('prepaga');
  }

  /// Perfil mínimo para ingresar cuando get_cliente falla por prepaga en lab.
  static app_user.User _minimalUserForLogin({
    required String email,
    required int cliIdCliente,
    app_user.User? hiveUser,
  }) {
    if (hiveUser != null &&
        (hiveUser.nombres.isNotEmpty || hiveUser.apellidos.isNotEmpty)) {
      return app_user.User(
        nombres: hiveUser.nombres,
        apellidos: hiveUser.apellidos,
        cedula: hiveUser.cedula,
        direccion: hiveUser.direccion,
        celular: hiveUser.celular,
        email: hiveUser.email,
        seguro: '',
        password: hiveUser.password,
        idCliente: hiveUser.idCliente ?? cliIdCliente,
        ruc: hiveUser.ruc,
        razonSocial: hiveUser.razonSocial,
        sexo: hiveUser.sexo,
      );
    }
    return app_user.User(
      nombres: '',
      apellidos: '',
      cedula: '',
      direccion: '',
      celular: '',
      email: email,
      seguro: '',
      password: '',
      idCliente: cliIdCliente,
    );
  }

  static Map<String, dynamic>? _extractClientePayload(dynamic responseData) {
    if (responseData == null || responseData is! Map) return null;

    final map = Map<String, dynamic>.from(responseData);

    if (map['clientes'] != null &&
        map['clientes'] is List &&
        (map['clientes'] as List).isNotEmpty) {
      return Map<String, dynamic>.from((map['clientes'] as List).first);
    }
    if (map['id_cliente'] != null || map['nombre'] != null) {
      return map;
    }
    if (map['cliente'] != null) {
      return Map<String, dynamic>.from(map['cliente']);
    }
    return null;
  }

  /// GET /app/get_cliente/:id con detalle de error (id = cli_id_cliente / id_cliente_final).
  static Future<ClientLoadResult> getClientByIdWithResult(int idCliente) async {
    print('🔍 [ClientApi] get_cliente/$idCliente');

    final responseData = await ApiClient.get('/app/get_cliente/$idCliente');

    if (responseData == null) {
      return ClientLoadResult(
        failureStep: 'get_cliente',
        failureDetail: 'sin respuesta (red o HTTP sin cuerpo)',
        clientIdUsed: idCliente,
      );
    }

    if (responseData is Map && responseData['_httpStatus'] == 404) {
      final errMap = Map<String, dynamic>.from(responseData);
      print('❌ [ClientApi] get_cliente 404: ${_extractApiMessage(errMap)}');
      return ClientLoadResult(
        failureStep: 'get_cliente HTTP 404',
        failureDetail: _extractApiMessage(errMap),
        clientIdUsed: idCliente,
        lastApiPayload: errMap,
      );
    }

    try {
      final clienteData = _extractClientePayload(responseData);
      if (clienteData != null) {
        final user = _mapClienteData(clienteData, idCliente)!;
        print('✅ [ClientApi] Cliente cargado: ${user.email} (id=${user.idCliente})');
        return ClientLoadResult(user: user, clientIdUsed: idCliente);
      }
      print('⚠️ [ClientApi] get_cliente sin estructura clientes[]: $responseData');
      return ClientLoadResult(
        failureStep: 'get_cliente',
        failureDetail: 'JSON sin datos de cliente reconocibles',
        clientIdUsed: idCliente,
        lastApiPayload: responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : null,
      );
    } catch (e, st) {
      print('🚨 [ClientApi] Error mapeando cliente: $e\n$st');
      return ClientLoadResult(
        failureStep: 'mapeo cliente',
        failureDetail: e.toString(),
        clientIdUsed: idCliente,
        lastApiPayload: responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : null,
      );
    }
  }

  // Obtener cliente por ID
  static Future<app_user.User?> getClientById(int idCliente) async {
    final result = await getClientByIdWithResult(idCliente);
    return result.user;
  }

  // Obtener respuesta de autenticación por email (para Google Login y verificaciones)
  static Future<Map<String, dynamic>?> getAuthResponseByEmail(String email) async {
    final responseData = await ApiClient.post('/app/post_autenticacion', {
      'email': email,
    });
    return responseData;
  }

  // Obtener ID por email (post_autenticacion con status success)
  static Future<int?> getClientIdByEmail(String email) async {
    final responseData = await getAuthResponseByEmail(email);

    if (responseData != null &&
        responseData['status'] == 'success' &&
        responseData['id_cliente'] != null) {
      return parseIdCliente(responseData['id_cliente']);
    }

    return null;
  }

  /// cli_id para get_cliente; ec_id para put_modificar_usuario (id_cliente_ec si viene en auth).
  static ({int? cliId, int? ecId}) _resolveClientIds(Map<String, dynamic> authData) {
    final cliId = parseIdCliente(authData['id_cliente']);
    final ecId = parseIdCliente(authData['id_cliente_ec']) ?? cliId;
    return (cliId: cliId, ecId: ecId);
  }

  /// Carga cliente tras post_autenticacion usando el id ya obtenido (evita 2.ª llamada).
  static Future<ClientLoadResult> loadClientAfterAuth({
    required String email,
    required Map<String, dynamic> authData,
  }) async {
    final ids = _resolveClientIds(authData);
    final idClienteCli = ids.cliId;
    final idClienteEc = ids.ecId;
    print(
      '🔍 [ClientApi] loadClientAfterAuth email=$email '
      'status=${authData['status']} cli=$idClienteCli ec=$idClienteEc',
    );

    if (idClienteCli == null) {
      return ClientLoadResult(
        failureStep: 'post_autenticacion',
        failureDetail: 'respuesta sin id_cliente válido: ${authData['id_cliente']}',
        lastApiPayload: authData,
      );
    }

    final fetchResult = await getClientByIdWithResult(idClienteCli);
    if (fetchResult.isSuccess) {
      return fetchResult;
    }

    app_user.User? hiveUser;
    try {
      hiveUser = await UserService.getUserByEmail(email);
    } catch (e) {
      print('🚨 [ClientApi] Error Hive: $e');
    }

    // Fallback: sin prepaga en lab → permitir login; completar en Mi Perfil
    if (_isMissingPrepagaError(fetchResult)) {
      print('⚠️ [ClientApi] Prepaga pendiente en lab; login con perfil mínimo');
      var user = _minimalUserForLogin(
        email: email,
        cliIdCliente: idClienteCli,
        hiveUser: hiveUser,
      );
      if (idClienteEc != null) {
        user = app_user.User(
          nombres: user.nombres,
          apellidos: user.apellidos,
          cedula: user.cedula,
          direccion: user.direccion,
          celular: user.celular,
          email: user.email,
          seguro: user.seguro,
          password: user.password,
          idCliente: idClienteEc,
          ruc: user.ruc,
          razonSocial: user.razonSocial,
          sexo: user.sexo,
        );
      }
      return ClientLoadResult(
        user: user,
        clientIdUsed: idClienteCli,
        requiresPrepagaSetup: true,
        failureDetail: fetchResult.failureDetail,
      );
    }

    if (hiveUser != null) {
      var user = _minimalUserForLogin(
        email: email,
        cliIdCliente: idClienteCli,
        hiveUser: hiveUser,
      );
      if (idClienteEc != null) {
        user = app_user.User(
          nombres: user.nombres,
          apellidos: user.apellidos,
          cedula: user.cedula,
          direccion: user.direccion,
          celular: user.celular,
          email: user.email,
          seguro: user.seguro,
          password: user.password,
          idCliente: idClienteEc,
          ruc: user.ruc,
          razonSocial: user.razonSocial,
          sexo: user.sexo,
        );
      }
      print('✅ [ClientApi] Cliente desde Hive (cli=$idClienteCli ec=$idClienteEc)');
      return ClientLoadResult(
        user: user,
        clientIdUsed: idClienteCli,
        failureDetail: 'get_cliente falló; datos locales: ${fetchResult.debugMessage}',
      );
    }

    return ClientLoadResult(
      failureStep: fetchResult.failureStep ?? 'get_cliente',
      failureDetail: fetchResult.failureDetail ?? 'sin datos locales en Hive',
      clientIdUsed: idClienteCli,
      lastApiPayload: fetchResult.lastApiPayload,
    );
  }

  // Obtener cliente completo por email (Orquestador)
  static Future<app_user.User?> getClientByEmail(String email) async {
    print('🔄 [ClientApi] getClientByEmail: $email');

    final authData = await getAuthResponseByEmail(email);
    if (authData == null) {
      print('❌ post_autenticacion sin respuesta');
      return null;
    }

    if (authData['status'] != 'success') {
      print(
        '❌ post_autenticacion status=${authData['status']}: '
        '${_extractApiMessage(Map<String, dynamic>.from(authData))}',
      );
      return null;
    }

    final result = await loadClientAfterAuth(email: email, authData: authData);
    return result.user;
  }

  /// Versión con detalle de error para pantallas de login.
  static Future<ClientLoadResult> getClientByEmailWithResult(String email) async {
    final authData = await getAuthResponseByEmail(email);
    if (authData == null) {
      return const ClientLoadResult(
        failureStep: 'post_autenticacion',
        failureDetail: 'sin respuesta del servidor',
      );
    }
    if (authData['status'] != 'success') {
      return ClientLoadResult(
        failureStep: 'post_autenticacion status=${authData['status']}',
        failureDetail: _extractApiMessage(Map<String, dynamic>.from(authData)),
        lastApiPayload: Map<String, dynamic>.from(authData),
      );
    }
    return loadClientAfterAuth(
      email: email,
      authData: Map<String, dynamic>.from(authData),
    );
  }

  // Reset Password
  static Future<bool> requestPasswordReset(String email) async {
    final responseData = await ApiClient.post('/app/user/password_reset', {
      'email': email,
    });

    if (responseData != null) {
      // Asumimos éxito si responde 200
      return responseData['status'] == 'success' || responseData['message'] != null;
    }
    return false;
  }

  // Actualizar Cliente
  static Future<Map<String, dynamic>?> updateClientData({
    required int idCliente,
    required String idPrepaga,
    String? telefono,
    String? direccion,
  }) async {
    // Validaciones de negocio antes de llamar a la API
    if (idPrepaga.isEmpty) return {'success': false, 'message': 'Falta prepaga'};
    if (telefono == null || telefono.isEmpty) return {'success': false, 'message': 'Falta teléfono'};
    if (direccion == null || direccion.isEmpty) return {'success': false, 'message': 'Falta dirección'};

    final body = {
      'idCliente': idCliente.toString(),
      'telefono': telefono.trim(),
      'direccion': direccion.trim(),
      'idPrepaga': idPrepaga.trim(),
    };

    final responseData = await ApiClient.put('/app/put_modificar_usuario', body);

    if (responseData != null) {
      if (responseData['status'] == 'success') {
        return {
          'success': true,
          'message': responseData['mensaje'] ?? 'Actualizado correctamente',
          'id_cliente': responseData['id_cliente']
        };
      } else {
        // Si la API responde 200 pero con status error en el JSON
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['description'] ?? 'Error desconocido'
        };
      }
    }

    return {'success': false, 'message': 'Error de conexión'};
  }

  // Solicitar Baja de Cuenta
  static Future<Map<String, dynamic>> requestAccountDeletion(int idCliente) async {
    try {
      // Usamos la ruta configurada en ORDS según la imagen
      final responseData = await ApiClient.post('/app/profile/account/delete', {
        'id_cliente': idCliente,
      });

      if (responseData != null) {
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            // Retornamos el mensaje exacto que viene desde el PL/SQL
            'message': responseData['mensaje'] ?? 'Cuenta en proceso de eliminación.'
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? responseData['description'] ?? 'Error al procesar la solicitud.'
          };
        }
      }
      return {'success': false, 'message': 'No se recibió respuesta del servidor.'};
    } catch (e) {
      print('🚨 Error al solicitar baja de cuenta: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor.'};
    }
  }

  // --- MÉTODOS PARA REACTIVACIÓN DE CUENTA ---

  // 1. Verificar si la cuenta está bloqueada (get_cliente usa cli_id_cliente)
  static Future<bool> isAccountBlocked(
    int idCliente, {
    int? cliIdCliente,
  }) async {
    final getId = cliIdCliente ?? idCliente;
    try {
      final responseData = await ApiClient.get('/app/get_cliente/$getId');

      if (responseData != null) {
        Map<String, dynamic>? clienteData;

        // Mapeo basado en la estructura de tu procedimiento (JSON_ARRAYAGG)
        if (responseData['clientes'] != null &&
            responseData['clientes'] is List &&
            responseData['clientes'].isNotEmpty) {
          clienteData = responseData['clientes'][0];
        } else if (responseData['id_cliente'] != null) {
          clienteData = responseData;
        }

        // Retorna true solo si el campo bloqueado es exactamente 'SI'
        if (clienteData != null && clienteData['bloqueado'] == 'SI') {
          return true;
        }
      }
    } catch (e) {
      print('🚨 Error verificando estado de bloqueo: $e');
    }
    return false; // Por defecto asumimos que no está bloqueado
  }

  // 2. Llamar al endpoint de Reactivación
  static Future<Map<String, dynamic>> reactivateAccount(int idCliente) async {
    try {
      final responseData = await ApiClient.post('/app/profile/account/reactivate', {
        'id_cliente': idCliente,
      });

      if (responseData != null && responseData['status'] == 'success') {
        return {'success': true, 'message': responseData['mensaje'] ?? 'Cuenta reactivada correctamente.'};
      }
      return {'success': false, 'message': responseData?['mensaje'] ?? 'Error al intentar reactivar la cuenta.'};
    } catch (e) {
      print('🚨 Error en API de reactivación: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor.'};
    }
  }
}
