import '../services/api_client.dart';

class SupportService {

  /// Obtiene los datos de soporte (email y teléfono) desde la API.
  Future<Map<String, String>> getSupportInfo() async {
    final response = await ApiClient.get('/app/parametros');

    // Valores por defecto en caso de error o falta de internet
    String email = 'atencion@certiva.com.py';
    String phone = '+595217283080';

    // Validamos la estructura basada en tu captura de Postman:
    // { "success": true, "data": { "email": "...", "phone": "..." } }
    if (response != null && response['success'] == true && response['data'] != null) {
      final data = response['data'];

      if (data['email'] != null) {

        email = data['email'].toString();
        print('Email recuperado: $email');
      }
      if (data['phone'] != null) {
        phone = data['phone'].toString();
        print('Teléfono recuperado: $phone');
      }
    }

    return {
      'email': email,
      'phone': phone,
    };
  }
}