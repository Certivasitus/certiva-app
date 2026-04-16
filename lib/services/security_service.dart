import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static final LocalAuthentication _auth = LocalAuthentication();

  // Claves para el storage seguro
  static const _keyEmail = 'biometric_email';
  static const _keyPassword = 'biometric_password';
  static const _keyBiometricEnabled = 'biometric_enabled';

  // 1. Verifica si el dispositivo soporta biometría
  static Future<bool> isBiometricSupported() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // 2. Verifica si el usuario activó la biometría en la app
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _keyBiometricEnabled);
    return enabled == 'true';
  }

  // 3. Autenticar con el sensor del teléfono
  static Future<bool> authenticateWithBiometrics() async {
    try {
      // 👇 SINTAXIS OFICIAL PARA LOCAL_AUTH 3.0.1 👇
      return await _auth.authenticate(
        localizedReason: 'Inicia sesión en Certiva',
        biometricOnly: true, // Solo permite biometría (no PIN)
        persistAcrossBackgrounding: true, // Reemplazo moderno de stickyAuth
      );
    } catch (e) {
      print('Error biométrico: $e');
      return false;
    }
  }

  // 4. Guardar credenciales seguras (Se llama cuando el usuario dice "SÍ")
  static Future<void> enableBiometricLogin(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  // 5. Obtener credenciales guardadas
  static Future<Map<String, String>?> getSavedBiometricCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  // 6. Desactivar (Si el usuario cierra sesión manualmente desde Perfil)
  static Future<void> disableBiometricLogin() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyBiometricEnabled);
  }
}