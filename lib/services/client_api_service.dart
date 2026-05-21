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
    final prepagaNombre = clienteData['prepaga_nombre']?.toString().trim();
    return app_user.User(
      nombres: clienteData['nombre'] ?? '',
      apellidos: clienteData['apellido'] ?? '',
      cedula: clienteData['cedula']?.toString() ?? '',
      direccion: clienteData['direccion'] ?? '',
      celular: clienteData['telefono'] ?? '',
      email: clienteData['email'] ?? '',
      seguro: clienteData['prepaga']?.toString() ?? '',
      seguroNombre:
          prepagaNombre != null && prepagaNombre.isNotEmpty
              ? prepagaNombre
              : null,
      password: '',
      // id_cliente JSON = ec_cliente; id_cliente_final = cliente.cli_id_cliente
      idCliente: parseIdCliente(clienteData['id_cliente']) ?? idClienteFallback,
      cliIdCliente: parseIdCliente(clienteData['id_cliente_final']),
      ruc: clienteData['ruc']?.toString(),
      razonSocial: clienteData['razon_social']?.toString(),
      sexo: clienteData['sex_id_sexo']?.toString(),
    );
  }

  static app_user.User _userWithResolvedIds(
    app_user.User user, {
    required int cliId,
    int? ecId,
  }) {
    return app_user.User(
      nombres: user.nombres,
      apellidos: user.apellidos,
      cedula: user.cedula,
      direccion: user.direccion,
      celular: user.celular,
      email: user.email,
      seguro: user.seguro,
      seguroNombre: user.seguroNombre,
      password: user.password,
      idCliente: ecId ?? user.idCliente,
      cliIdCliente: cliId,
      ruc: user.ruc,
      razonSocial: user.razonSocial,
      sexo: user.sexo,
    );
  }

  /// ID de tabla CLIENTE (cli_id_cliente) para get_agenda, post_agendar_turno, etc.
  /// get_cliente/:id recibe ec_cliente.id_cliente y devuelve id_cliente_final.
  static Future<int?> resolveLabClientId(app_user.User user) async {
    final ecId = user.idCliente;
    print(
      '🔍 [ClientApi] resolveLabClientId '
      'ec=$ecId cli_memoria=${user.cliIdCliente} email=${user.email}',
    );

    if (user.cliIdCliente != null) {
      return user.cliIdCliente;
    }

    if (ecId != null) {
      final fetch = await getClientByIdWithResult(ecId);
      final cliFromApi = fetch.user?.cliIdCliente ??
          parseIdCliente(
            _extractClientePayload(fetch.lastApiPayload)?['id_cliente_final'],
          );
      if (cliFromApi != null) {
        print('✅ [ClientApi] cli_id=$cliFromApi vía get_cliente/$ecId (ec)');
        return cliFromApi;
      }
      print(
        '⚠️ [ClientApi] get_cliente/$ecId sin id_cliente_final: '
        '${fetch.debugMessage}',
      );
    }

    if (user.email.isNotEmpty) {
      final auth = await getAuthResponseByEmail(user.email);
      if (auth != null) {
        final cliFromAuth = parseIdCliente(auth['id_cliente']);
        if (cliFromAuth != null) {
          print('✅ [ClientApi] cli_id=$cliFromAuth vía post_autenticacion');
          return cliFromAuth;
        }
      }
    }

    print('❌ [ClientApi] No se pudo resolver cli_id_cliente');
    return null;
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

  /// GET /app/get_cliente/:id — [ecId] = ec_cliente.id_cliente.
  static Future<ClientLoadResult> getClientByIdWithResult(int ecId) async {
    print(
      '🔍 [ClientApi] GET /app/get_cliente/$ecId '
      '(ec_cliente.id → respuesta id_cliente_final = cli)',
    );

    final responseData = await ApiClient.get('/app/get_cliente/$ecId');

    if (responseData == null) {
      return ClientLoadResult(
        failureStep: 'get_cliente',
        failureDetail: 'sin respuesta (red o HTTP sin cuerpo)',
        clientIdUsed: ecId,
      );
    }

    if (responseData is Map && responseData['_httpStatus'] == 404) {
      final errMap = Map<String, dynamic>.from(responseData);
      print('❌ [ClientApi] get_cliente/$ecId 404: ${_extractApiMessage(errMap)}');
      return ClientLoadResult(
        failureStep: 'get_cliente HTTP 404',
        failureDetail: _extractApiMessage(errMap),
        clientIdUsed: ecId,
        lastApiPayload: errMap,
      );
    }

    if (responseData is Map &&
        (responseData['code'] != null || responseData['codigo'] != null)) {
      final errMap = Map<String, dynamic>.from(responseData);
      print(
        '❌ [ClientApi] get_cliente/$ecId error: ${_extractApiMessage(errMap)}',
      );
      return ClientLoadResult(
        failureStep: 'get_cliente error API',
        failureDetail: _extractApiMessage(errMap),
        clientIdUsed: ecId,
        lastApiPayload: errMap,
      );
    }

    try {
      final clienteData = _extractClientePayload(responseData);
      if (clienteData != null) {
        final idEc = parseIdCliente(clienteData['id_cliente']);
        final idCli = parseIdCliente(clienteData['id_cliente_final']);
        print(
          '📋 [ClientApi] get_cliente/$ecId → '
          'id_cliente(ec)=$idEc id_cliente_final(cli)=$idCli',
        );
        final user = _mapClienteData(clienteData, ecId)!;
        print(
          '✅ [ClientApi] ${user.email} ec=${user.idCliente} cli=${user.cliIdCliente}',
        );
        return ClientLoadResult(user: user, clientIdUsed: ecId);
      }
      print(
        '⚠️ [ClientApi] get_cliente sin estructura clientes[]: $responseData',
      );
      return ClientLoadResult(
        failureStep: 'get_cliente',
        failureDetail: 'JSON sin datos de cliente reconocibles',
        clientIdUsed: ecId,
        lastApiPayload:
            responseData is Map
                ? Map<String, dynamic>.from(responseData)
                : null,
      );
    } catch (e, st) {
      print('🚨 [ClientApi] Error mapeando cliente: $e\n$st');
      return ClientLoadResult(
        failureStep: 'mapeo cliente',
        failureDetail: e.toString(),
        clientIdUsed: ecId,
        lastApiPayload:
            responseData is Map
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
  static Future<Map<String, dynamic>?> getAuthResponseByEmail(
    String email,
  ) async {
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

  /// post_autenticacion: id_cliente = cli (lab), id_cliente_ec = ec_cliente PK.
  static ({int? cliId, int? ecId}) _resolveClientIds(
    Map<String, dynamic> authData,
  ) {
    final cliId = parseIdCliente(authData['id_cliente']);
    final ecId = parseIdCliente(authData['id_cliente_ec']);
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

    if (idClienteCli == null && idClienteEc == null) {
      return ClientLoadResult(
        failureStep: 'post_autenticacion',
        failureDetail:
            'respuesta sin id_cliente válido: ${authData['id_cliente']}',
        lastApiPayload: authData,
      );
    }

    final ecForGet = idClienteEc ?? idClienteCli;
    final fetchResult = await getClientByIdWithResult(ecForGet!);
    if (fetchResult.isSuccess && fetchResult.user != null) {
      final cliId = fetchResult.user!.cliIdCliente ?? idClienteCli ?? ecForGet;
      return ClientLoadResult(
        user: _userWithResolvedIds(
          fetchResult.user!,
          cliId: cliId,
          ecId: idClienteEc ?? fetchResult.user!.idCliente,
        ),
        clientIdUsed: ecForGet,
      );
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
      final cliFallback = idClienteCli ?? ecForGet;
      var user = _minimalUserForLogin(
        email: email,
        cliIdCliente: cliFallback,
        hiveUser: hiveUser,
      );
      user = _userWithResolvedIds(
        user,
        cliId: cliFallback,
        ecId: idClienteEc,
      );
      return ClientLoadResult(
        user: user,
        clientIdUsed: ecForGet,
        requiresPrepagaSetup: true,
        failureDetail: fetchResult.failureDetail,
      );
    }

    if (hiveUser != null) {
      final cliFallback = idClienteCli ?? ecForGet;
      var user = _minimalUserForLogin(
        email: email,
        cliIdCliente: cliFallback,
        hiveUser: hiveUser,
      );
      user = _userWithResolvedIds(
        user,
        cliId: cliFallback,
        ecId: idClienteEc,
      );
      print(
        '✅ [ClientApi] Cliente desde Hive (cli=$idClienteCli ec=$idClienteEc)',
      );
      return ClientLoadResult(
        user: user,
        clientIdUsed: ecForGet,
        failureDetail:
            'get_cliente falló; datos locales: ${fetchResult.debugMessage}',
      );
    }

    return ClientLoadResult(
      failureStep: fetchResult.failureStep ?? 'get_cliente',
      failureDetail: fetchResult.failureDetail ?? 'sin datos locales en Hive',
      clientIdUsed: ecForGet,
      lastApiPayload: fetchResult.lastApiPayload,
    );
  }

  /// Perfil completo para Mi Perfil: post_autenticacion + get_cliente(ec_id).
  static Future<app_user.User?> fetchClientProfileByEmail(String email) async {
    print('🔄 [ClientApi] fetchClientProfileByEmail: $email');

    final authData = await getAuthResponseByEmail(email);
    if (authData == null) {
      try {
        return await UserService.getUserByEmail(email);
      } catch (_) {
        return null;
      }
    }

    final ids = _resolveClientIds(authData);
    if (ids.cliId == null) {
      try {
        return await UserService.getUserByEmail(email);
      } catch (_) {
        return null;
      }
    }

    if (authData['status'] == 'success') {
      final result = await loadClientAfterAuth(
        email: email,
        authData: Map<String, dynamic>.from(authData),
      );
      if (result.user != null) return result.user;
    } else {
      final ecForGet = ids.ecId ?? ids.cliId;
      if (ecForGet == null) {
        try {
          return await UserService.getUserByEmail(email);
        } catch (_) {
          return null;
        }
      }
      final fetch = await getClientByIdWithResult(ecForGet);
      if (fetch.isSuccess && fetch.user != null) {
        return _userWithResolvedIds(
          fetch.user!,
          cliId: fetch.user!.cliIdCliente ?? ids.cliId ?? ecForGet,
          ecId: ids.ecId ?? fetch.user!.idCliente,
        );
      }
    }

    try {
      return await UserService.getUserByEmail(email);
    } catch (_) {
      return null;
    }
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
  static Future<ClientLoadResult> getClientByEmailWithResult(
    String email,
  ) async {
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
      return responseData['status'] == 'success' ||
          responseData['message'] != null;
    }
    return false;
  }

  // Actualizar Cliente (PUT /app/put_modificar_usuario → pr_lab_update_cliente_json)
  static Future<Map<String, dynamic>?> updateClientData({
    required int idCliente,
    required String idPrepaga,
    String? telefono,
    String? direccion,
    String? nombre,
    String? apellido,
    String? email,
    String? cedula,
  }) async {
    if (idPrepaga.isEmpty)
      return {'success': false, 'message': 'Falta prepaga'};
    if (telefono == null || telefono.isEmpty) {
      return {'success': false, 'message': 'Falta teléfono'};
    }
    if (direccion == null || direccion.isEmpty) {
      return {'success': false, 'message': 'Falta dirección'};
    }

    final body = <String, dynamic>{
      'idCliente': idCliente,
      'telefono': telefono.trim(),
      'direccion': direccion.trim(),
      'idPrepaga': int.tryParse(idPrepaga.trim()) ?? idPrepaga.trim(),
    };

    if (nombre != null && nombre.isNotEmpty) body['nombre'] = nombre.trim();
    if (apellido != null && apellido.isNotEmpty)
      body['apellido'] = apellido.trim();
    if (email != null && email.isNotEmpty) body['email'] = email.trim();
    if (cedula != null && cedula.isNotEmpty) body['cedula'] = cedula.trim();

    print('🚀 [ClientApi] PUT /app/put_modificar_usuario | Body: $body');
    final responseData = await ApiClient.put(
      '/app/put_modificar_usuario',
      body,
    );

    if (responseData != null) {
      if (responseData['status'] == 'success') {
        return {
          'success': true,
          'message': responseData['mensaje'] ?? 'Actualizado correctamente',
          'id_cliente': responseData['id_cliente'],
        };
      }
      return {
        'success': false,
        'message': _extractApiMessage(
          responseData is Map ? Map<String, dynamic>.from(responseData) : null,
        ),
      };
    }

    return {'success': false, 'message': 'Error de conexión con el servidor.'};
  }

  // Solicitar Baja de Cuenta
  static Future<Map<String, dynamic>> requestAccountDeletion(
    int idCliente,
  ) async {
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
            'message':
                responseData['mensaje'] ?? 'Cuenta en proceso de eliminación.',
          };
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ??
                responseData['description'] ??
                'Error al procesar la solicitud.',
          };
        }
      }
      return {
        'success': false,
        'message': 'No se recibió respuesta del servidor.',
      };
    } catch (e) {
      print('🚨 Error al solicitar baja de cuenta: $e');
      return {
        'success': false,
        'message': 'Error de conexión con el servidor.',
      };
    }
  }

  // --- MÉTODOS PARA REACTIVACIÓN DE CUENTA ---

  // 1. Verificar bloqueo — get_cliente/:id usa ec_cliente.id_cliente
  static Future<bool> isAccountBlocked(int ecIdCliente) async {
    try {
      final responseData = await ApiClient.get('/app/get_cliente/$ecIdCliente');

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
      final responseData = await ApiClient.post(
        '/app/profile/account/reactivate',
        {'id_cliente': idCliente},
      );

      if (responseData != null && responseData['status'] == 'success') {
        return {
          'success': true,
          'message':
              responseData['mensaje'] ?? 'Cuenta reactivada correctamente.',
        };
      }
      return {
        'success': false,
        'message':
            responseData?['mensaje'] ??
            'Error al intentar reactivar la cuenta.',
      };
    } catch (e) {
      print('🚨 Error en API de reactivación: $e');
      return {
        'success': false,
        'message': 'Error de conexión con el servidor.',
      };
    }
  }
}
