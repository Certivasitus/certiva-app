import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Obtenemos los valores del .env, con un valor por defecto por seguridad si falla
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get _apiUser => dotenv.env['API_USER'] ?? '';
  static String get _apiPass => dotenv.env['API_PASS'] ?? '';

  // Getter para obtener el Header de Autenticación listo para usar
  static String get basicAuthToken {
    final String rawAuth = '${Uri.encodeComponent(_apiUser)}:${Uri.encodeComponent(_apiPass)}';
    return 'Basic ' + base64Encode(utf8.encode(rawAuth));
  }

  // Headers comunes (JSON + Auth)
  static Map<String, String> get defaultHeaders => {
    'Authorization': basicAuthToken,
    'Content-Type': 'application/json',
  };
}