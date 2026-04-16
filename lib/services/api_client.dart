import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {

  /// Construye los headers combinando los predeterminados con los personalizados
  static Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final requestHeaders = _buildHeaders(headers);

    print('🌐 [GET] $url');

    try {
      final response = await http.get(url, headers: requestHeaders);
      return _processResponse(response);
    } catch (e) {
      print('🚨 [ApiClient] Error de conexión GET: $e');
      return null;
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final requestHeaders = _buildHeaders(headers);

    print('🌐 [POST] $url');

    try {
      final response = await http.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      print('🚨 [ApiClient] Error de conexión POST: $e');
      return null;
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body, {Map<String, String>? headers}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final requestHeaders = _buildHeaders(headers);

    print('🌐 [PUT] $url');

    try {
      final response = await http.put(
        url,
        headers: requestHeaders,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      print('🚨 [ApiClient] Error de conexión PUT: $e');
      return null;
    }
  }

  /// Procesa la respuesta HTTP y decodifica el JSON.
  /// En caso de error (400/500), intenta extraer el mensaje de validación de APEX.
  static dynamic _processResponse(http.Response response) {
    print('📥 [STATUS] ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body);
      } catch (e) {
        print('⚠️ [ApiClient] Error al decodificar JSON exitoso: $e');
        return null;
      }
    } else if (response.statusCode == 404) {
      print('❌ [ApiClient] Recurso no encontrado (404)');
      return null;
    } else {
      print('❌ [ApiClient] Error HTTP ${response.statusCode}');
      try {
        // Retornamos el JSON del error para leer los mensajes descriptivos del backend
        return jsonDecode(response.body);
      } catch (e) {
        print('⚠️ [ApiClient] La respuesta de error no es un JSON válido.');
        return null;
      }
    }
  }
}