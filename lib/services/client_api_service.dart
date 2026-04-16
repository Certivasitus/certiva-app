import '../models/user.dart' as app_user;
import 'user_service.dart';
import 'api_client.dart';

class ClientApiService {

  // Obtener cliente por ID
  static Future<app_user.User?> getClientById(int idCliente) async {

    final responseData = await ApiClient.get('/app/get_cliente/$idCliente');

    if (responseData == null) return null;

    try {
      Map<String, dynamic>? clienteData;

      if (responseData['clientes'] != null &&
          responseData['clientes'] is List &&
          responseData['clientes'].isNotEmpty) {
        clienteData = responseData['clientes'][0];
      }
      else if (responseData['id_cliente'] != null || responseData['nombre'] != null) {
        clienteData = responseData;
      }
      else if (responseData['cliente'] != null) {
        clienteData = responseData['cliente'];
      }

      if (clienteData != null) {
        return app_user.User(
          nombres: clienteData['nombre'] ?? '',
          apellidos: clienteData['apellido'] ?? '',
          cedula: clienteData['cedula']?.toString() ?? '',
          direccion: clienteData['direccion'] ?? '',
          celular: clienteData['telefono'] ?? '',
          email: clienteData['email'] ?? '',
          seguro: clienteData['prepaga']?.toString() ?? '',
          password: '',
          idCliente: clienteData['id_cliente'] ?? idCliente,
          ruc: clienteData['ruc']?.toString(),
          razonSocial: clienteData['razon_social']?.toString(),
          sexo: clienteData['sex_id_sexo']?.toString(),
        );
      }
    } catch (e) {
      print('🚨 Error al mapear datos del cliente: $e');
    }

    return null;
  }

  // Obtener ID por email
  static Future<int?> getClientIdByEmail(String email) async {
    final responseData = await ApiClient.post('/app/post_autenticacion', {
      'email': email,
    });

    if (responseData != null &&
        responseData['status'] == 'success' &&
        responseData['id_cliente'] != null) {
      return responseData['id_cliente'];
    }

    return null;
  }

  // Obtener cliente completo por email (Orquestador)
  static Future<app_user.User?> getClientByEmail(String email) async {
    print('🔄 [Logic] Iniciando búsqueda completa por email: $email');

    // Paso 1: Obtener ID
    final idCliente = await getClientIdByEmail(email);

    if (idCliente == null) {
      print('❌ No se encontró ID para este email');
      return null;
    }

    // Paso 2: Obtener Datos
    final user = await getClientById(idCliente);

    if (user != null) {
      return user;
    } else {
      // Fallback a Hive
      print('⚠️ API falló, intentando recuperar de Hive...');
      try {
        final hiveUser = await UserService.getUserByEmail(email);
        if (hiveUser != null) {
          // Actualizar ID si es necesario
          if (hiveUser.idCliente == null || hiveUser.idCliente != idCliente) {
            return app_user.User(
              nombres: hiveUser.nombres,
              apellidos: hiveUser.apellidos,
              cedula: hiveUser.cedula,
              direccion: hiveUser.direccion,
              celular: hiveUser.celular,
              email: hiveUser.email,
              seguro: hiveUser.seguro,
              password: hiveUser.password,
              idCliente: idCliente, // ID actualizado
              ruc: hiveUser.ruc,
              razonSocial: hiveUser.razonSocial,
              sexo: hiveUser.sexo,
            );
          }
          return hiveUser;
        }
      } catch (e) {
        print('Error Hive: $e');
      }
      return null;
    }
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

  // 1. Verificar si la cuenta está bloqueada
  static Future<bool> isAccountBlocked(int idCliente) async {
    try {
      final responseData = await ApiClient.get('/app/get_cliente/$idCliente');

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

