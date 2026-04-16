import 'package:uuid/uuid.dart';
import 'api_client.dart';
import 'user_service.dart';
import '../models/user.dart' as app_user;
import 'dart:math';

// --- MODELOS ---

class ChatConfig {
  final String mensajeBienvenida;
  final String nombreAsistente;
  final String colorPrimario; // Color del agente
  final String colorUsuario;  // Color del usuario
  final int idAgente;

  ChatConfig({
    required this.mensajeBienvenida,
    required this.nombreAsistente,
    required this.colorPrimario,
    required this.colorUsuario,
    required this.idAgente,
  });

  factory ChatConfig.fromJson(Map<String, dynamic> json) {
    return ChatConfig(
      mensajeBienvenida: json['mensaje_bienvenida'] ?? '¡Hola! ¿En qué puedo ayudarte?',
      nombreAsistente: json['nombre_asistente'] ?? 'Asistente Virtual',
      colorPrimario: json['color_primario'] ?? '#1ce5c3',
      colorUsuario: json['color_usuario'] ?? '#b18bd3',
      // Convertimos a int de forma segura, con fallback a 1 por defecto
      idAgente: int.tryParse(json['id_agente']?.toString() ?? '1') ?? 1,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String dateStr;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.dateStr,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['texto'] ?? '',
      isUser: json['tipo'] == 'U',
      dateStr: json['hora'] ?? '',
    );
  }
}

// --- SERVICIO ---

class CertivaChatService {
  final String _baseEndpoint = '/v1/chat';

  String? _idSesionApp;
  final Uuid _uuid = const Uuid();

  int _idAgenteActual = 1;

  static final CertivaChatService _instance = CertivaChatService._internal();
  factory CertivaChatService() => _instance;
  CertivaChatService._internal();

  String get idSesionApp {
    if (_idSesionApp == null) {
      final random = Random();
      // Genera un número entre 100000000 y 999999999
      final numId = 100000000 + random.nextInt(900000000);
      _idSesionApp = numId.toString();
    }
    return _idSesionApp!;
  }

  void resetSession() {
    _idSesionApp = null;
  }

  Future<ChatConfig> getConfig() async {
    final response = await ApiClient.get('$_baseEndpoint/config');

    if (response != null && response['mensaje'] == null) {
      final config = ChatConfig.fromJson(response);

      _idAgenteActual = config.idAgente;

      return config;
    }

    // Si la API falla, retornamos el config con los valores por defecto
    return ChatConfig.fromJson({});
  }

  Future<List<ChatMessage>> getHistory() async {
    final response = await ApiClient.get('$_baseEndpoint/history/$idSesionApp');

    if (response != null && response['mensajes'] != null) {
      final List<dynamic> mensajesJson = response['mensajes'];
      return mensajesJson.map((json) => ChatMessage.fromJson(json)).toList();
    }

    if (response != null && response['mensaje'] != null) {
      throw Exception(response['mensaje']);
    }

    return [];
  }

  Future<String> sendMessage(String text) async {
    final app_user.User? currentUser = UserService.getCurrentUser();

    final body = {
      'id_cliente': currentUser?.idCliente?.toString(),
      'email_usuario': currentUser?.email,
      'pregunta': text,
      'id_sesion_app': idSesionApp,
      'id_agente': _idAgenteActual
    };

    // --- LOG DE DEPURACIÓN DE ENVÍO ---
    print('=============================================');
    print('🚀 [CertivaChatService] ENVIANDO MENSAJE');
    print('📍 URL: $_baseEndpoint/send');
    print('📦 PAYLOAD ENVIADO:');
    print(body);
    print('=============================================');

    try {
      final response = await ApiClient.post('$_baseEndpoint/send', body);

      // --- LOG DE DEPURACIÓN DE RESPUESTA ---
      print('=============================================');
      print('📥 [CertivaChatService] RESPUESTA RECIBIDA');
      print(response);
      print('=============================================');

      if (response != null) {
        if (response['status'] == 'success') {
          return response['respuesta'] ?? 'Sin respuesta del asistente.';
        } else {
          final errorMsg = response['mensaje'] ??
              response['message'] ??
              response['error'] ??
              'Error del servidor (Status no es success, pero no se encontró la clave de error en el JSON)';

          print('🚨 [CertivaChatService] FALLO CONTROLADO DEL BACKEND: $errorMsg');
          throw Exception(errorMsg);
        }
      } else {
        print('🚨 [CertivaChatService] RESPUESTA ES NULL');
        throw Exception('El servidor no devolvió datos (Response is null)');
      }
    } catch (e) {
      print('🔥 [CertivaChatService] EXCEPCIÓN CAPTURADA: $e');
      throw Exception('Error al enviar el mensaje: $e');
    }
  }
}