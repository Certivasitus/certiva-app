import 'package:flutter/material.dart';

// 1. Definimos los tipos de mensajes disponibles
enum SnackBarType {
  success,
  error,
  warning,
  info
}

class CustomSnackBar {

  // 2. Método principal unificado que usa la pantalla nueva
  static void show(BuildContext context, {required String message, required SnackBarType type}) {
    Color backgroundColor;
    IconData icon;
    String title;

    // Configuramos color e ícono según el tipo
    switch (type) {
      case SnackBarType.success:
        backgroundColor = const Color(0xFF2E7D32); // Verde
        icon = Icons.check_circle_outline;
        title = '¡Éxito!';
        break;
      case SnackBarType.error:
        backgroundColor = const Color(0xFFD32F2F); // Rojo
        icon = Icons.error_outline_rounded;
        title = 'Error';
        break;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFFED6C02); // Naranja
        icon = Icons.warning_amber_rounded;
        title = 'Atención';
        break;
      case SnackBarType.info:
        backgroundColor = const Color(0xFF0288D1); // Azul
        icon = Icons.info_outline;
        title = 'Información';
        break;
    }

    _showRaw(
      context,
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
    );
  }

  // MÉTODOS LEGACY (Para compatibilidad con otras pantallas si las tienes)
  static void showSuccess(BuildContext context, {required String message, String title = '¡Todo listo!'}) {
    show(context, message: message, type: SnackBarType.success);
  }

  static void showError(BuildContext context, {required String message, String title = 'Error'}) {
    show(context, message: message, type: SnackBarType.error);
  }

  // Lógica privada de diseño
  static void _showRaw(
      BuildContext context, {
        required String message,
        required String title,
        required Color backgroundColor,
        required IconData icon,
      }) {
    // Evita acumulación de mensajes
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}