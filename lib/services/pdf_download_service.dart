import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../config/api_config.dart';

class PdfDownloadService {

  /// Descarga el PDF del análisis invocando el endpoint /app/get_pdf.
  /// Maneja la respuesta binaria (PDF) o los errores lógicos (JSON) que retorna el PL/SQL.
  static Future<Map<String, dynamic>> downloadPdf({
    required int idSolicitud,
    required int idFirma,
    String? nombreArchivo,
  }) async {
    // Construimos la URL con los parámetros query exactos que espera ORDS.
    // Usamos queryParameters para asegurar la correcta codificación de la URL.
    final uri = Uri.parse('${ApiConfig.baseUrl}/app/get_pdf').replace(
        queryParameters: {
          'IdSolicitud': idSolicitud.toString(),
          'IdFirma': idFirma.toString(),
        }
    );

    try {
      // Preparamos los headers utilizando la configuración centralizada.
      // Es crucial agregar 'Accept: application/pdf' para indicar el tipo de contenido esperado.
      final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
      headers['Accept'] = 'application/pdf';

      // Realizamos una petición directa con http.get en lugar de ApiClient
      // porque necesitamos procesar el flujo de bytes (bodyBytes) sin decodificación JSON automática.
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        // VERIFICACIÓN DE SEGURIDAD
        // El backend PL/SQL puede devolver un status 200 OK incluso si ocurre un error lógico,
        // retornando un JSON con la descripción del error en lugar del binario PDF.
        // Verificamos el Content-Type para evitar guardar un archivo corrupto (texto guardado como .pdf).
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/json')) {
          try {
            final jsonError = jsonDecode(response.body);
            return {
              'success': false,
              'message': jsonError['message'] ?? 'No se pudo generar el documento.'
            };
          } catch (_) {
            return {
              'success': false,
              'message': 'Error desconocido al procesar el archivo.'
            };
          }
        }

        // Si es un PDF real, obtenemos el directorio de documentos de la aplicación.
        // Este directorio es seguro y no requiere permisos de almacenamiento explícitos en Android 10+ ni iOS.
        final dir = await getApplicationDocumentsDirectory();

        final fileName = nombreArchivo ?? 'Estudio_${idSolicitud}_$idFirma.pdf';
        final file = File('${dir.path}/$fileName');

        // Escribimos los bytes directamente en el archivo y forzamos el flush para asegurar integridad.
        await file.writeAsBytes(response.bodyBytes, flush: true);

        // Abrimos el archivo utilizando el visor nativo del sistema operativo.
        final openResult = await OpenFilex.open(file.path);

        return {
          'success': true,
          'filePath': file.path,
          'fileName': fileName,
          'message': 'Descarga completada.',
          'openResult': openResult.type.toString()
        };

      } else {
        // Manejo de errores HTTP estándar (404, 500, etc.)
        return _handleHttpError(response);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión. Verifique su internet.',
      };
    }
  }

  // Extrae el mensaje de error del backend si está disponible en formato JSON,
  // de lo contrario devuelve un mensaje genérico basado en el código de estado.
  static Map<String, dynamic> _handleHttpError(http.Response response) {
    String msg = 'Error del servidor (${response.statusCode})';
    try {
      final jsonError = jsonDecode(response.body);
      if (jsonError['message'] != null) {
        msg = jsonError['message'];
      }
    } catch (_) {
      // La respuesta no es un JSON válido, mantenemos el mensaje por defecto.
    }

    return {
      'success': false,
      'message': msg,
    };
  }
}