import '../models/consultation.dart';
import 'api_client.dart';
import '../services/user_service.dart'; // Importante para obtener el email del usuario

class ConsultationService {
  static final ConsultationService _instance = ConsultationService._internal();
  factory ConsultationService() => _instance;
  ConsultationService._internal();

  /// Obtiene el historial de citas (agenda) de un cliente específico.
  Future<List<Consultation>> getAgendaFromAPI({
    required int idCliente,
    String? fecha,      // Formato DD-MM-YYYY
    int? idSucursal,
    String? estado,     // Parametro 'agenda' (RESERVADO, CERRADO, etc)
  }) async {
    // La URL base ya no lleva parámetros ni ID en el path, todo va por Header
    const endpoint = '/app/get_agenda';

    // Preparamos los HEADERS según tu configuración ORDS
    final Map<String, String> headers = {
      'ID_CLIENTE': idCliente.toString(),
    };

    // Agregar filtros solo si tienen valor
    if (fecha != null && fecha.isNotEmpty) {
      headers['fecha'] = fecha;
    }
    if (idSucursal != null && idSucursal > 0) {
      headers['id_sucursal'] = idSucursal.toString();
    }
    // Si es 'TODOS', no enviamos el header para que traiga todo (o según lógica de tu PL/SQL)
    if (estado != null && estado.isNotEmpty && estado != 'TODOS') {
      headers['agenda'] = estado;
    }

    print('🔍 [Service] Consultando Agenda Headers: $headers');

    final response = await ApiClient.get(endpoint, headers: headers);

    if (response != null && response['agendas'] != null) {
      final List<dynamic> agendas = response['agendas'];

      return agendas.map((agenda) {
        final estadoApi = agenda['estado']?.toString().toUpperCase();
        String status = estadoApi!;

        // Formateo visual de fecha
        String formattedDate = agenda['fecha_reserva'] ?? '';
        try {
          final parts = formattedDate.split('-');
          if (parts.length == 3) {
            if (parts[0].length == 4) {
              formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
            } else {
              formattedDate = '${parts[0]}/${parts[1]}/${parts[2]}';
            }
          }
        } catch (_) {}

        return Consultation(
          id: agenda['cod']?.toString() ?? '',
          specialty: agenda['nombre_especialidad'] ?? '',
          doctor: agenda['nombre_prestador'] ?? '',
          branch: agenda['nombre_sucursal'] ?? '',
          date: formattedDate,
          time: agenda['hora_turno'] ?? '',
          status: status,
          fechaOriginal: agenda['fecha_reserva'],
          createdAt: DateTime.now(),
        );
      }).toList();
    }
    return [];
  }

  /// Obtiene el catálogo de especialidades médicas disponibles.
  Future<List<Map<String, dynamic>>> getSpecialties() async {
    final response = await ApiClient.get('/app/get_especialidad');
    if (response != null && response['especialidades'] != null) {
      return List<Map<String, dynamic>>.from(response['especialidades']);
    }
    return [];
  }

  /// Obtiene el catálogo de sucursales disponibles.
  Future<List<Map<String, dynamic>>> getBranches() async {
    final response = await ApiClient.get('/app/get_sucursales');
    if (response != null && response['sucursales'] != null) {
      return List<Map<String, dynamic>>.from(response['sucursales']);
    }
    return [];
  }

  /// Método auxiliar para obtener doctores de una especialidad específica.
  Future<List<Map<String, dynamic>>> _getDoctorsBySpecialty(int codEspecialidad, String nombreEspecialidad) async {
    final response = await ApiClient.get('/app/get_prestadores/$codEspecialidad');
    if (response != null && response['prestadores'] != null) {
      final List<dynamic> prestadores = response['prestadores'];
      return prestadores.map((p) => {
        ...p as Map<String, dynamic>,
        'especialidad': nombreEspecialidad,
        'avatar_url': p['avatar_url'],
      }).toList();
    }
    return [];
  }

  /// Carga todos los doctores de todas las especialidades.
  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    try {
      final especialidades = await getSpecialties();
      if (especialidades.isEmpty) return [];

      final futures = especialidades.map((esp) =>
          _getDoctorsBySpecialty(
              esp['cod_especialidad'],
              esp['descripcion_especialidad']
          )
      );

      final results = await Future.wait(futures);
      final Map<int, Map<String, dynamic>> uniqueDoctors = {};

      for (var doctorsList in results) {
        for (var doc in doctorsList) {
          final int id = doc['cod_prestador'];
          final String espName = doc['especialidad'];

          if (uniqueDoctors.containsKey(id)) {
            final existingEntry = uniqueDoctors[id]!;
            List<String> listaEsp = List<String>.from(existingEntry['especialidades']);
            if (!listaEsp.contains(espName)) {
              listaEsp.add(espName);
              existingEntry['especialidades'] = listaEsp;
            }
          } else {
            uniqueDoctors[id] = {
              'cod_prestador': id,
              'nombre_prestador': doc['nombre_prestador'],
              'avatar_url': doc['avatar_url'],
              'especialidades': [espName],
              'especialidad': espName,
            };
          }
        }
      }
      return uniqueDoctors.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// Consulta los turnos disponibles enviando parámetros por HEADERS.
  Future<List<Map<String, dynamic>>> getTurnosDisponibles({
    required String fecha,
    int? prestador,
    int? especialidad,
    int? sucursal,
  }) async {

    // 1. Preparamos los HEADERS (No Query Params)
    // Usamos las claves exactas de la configuración de ORDS
    final Map<String, String> headers = {
      'FECHA': fecha, // Debe ser DD-MM-YYYY
    };

    if (prestador != null) headers['PRESTADOR'] = prestador.toString();
    if (especialidad != null) headers['ESPECIALIDAD'] = especialidad.toString();
    if (sucursal != null) headers['SUCURSAL'] = sucursal.toString();

    // 2. Agregamos el usuario logueado al header 'usuario' (en minúscula según ORDS)
    final currentUser = UserService.getCurrentUser();
    if (currentUser != null && currentUser.email.isNotEmpty) {
      headers['usuario'] = currentUser.email;
    }

    print('🔍 Consultando Turnos via HEADERS: $headers');

    // 3. Endpoint limpio (sin interrogación ?)
    const endpoint = '/app/get_turnos_disponibles';

    // Enviamos los headers en la petición GET
    // NOTA: ApiClient.get debe soportar el parámetro nominal 'headers'.
    final response = await ApiClient.get(endpoint, headers: headers);

    if (response != null && response['turnos'] != null) {
      return List<Map<String, dynamic>>.from(response['turnos']);
    }
    return [];
  }

  /// Realiza la reserva de un turno.
  Future<Map<String, dynamic>> agendarTurno({
    required String fechaReserva,
    required int idCliente,
    required int idPersonaProf,
    required int idDetAux,
    required int idBox,
    required int idSucursal,
    String? observacion,
  }) async {
    final body = {
      'fecha_reserva': fechaReserva,
      'id_cliente': idCliente,
      'id_persona_prof': idPersonaProf,
      'id_det_aux': idDetAux,
      'id_box': idBox,
      'id_sucursal': idSucursal,
      if (observacion != null) 'observacion': observacion,
    };

    final response = await ApiClient.post('/app/post_agendar_turno', body);

    if (response != null) {
      if (response['status'] == 'success' || response['success'] == true) {
        return {
          'success': true,
          'message': response['mensaje'] ?? 'Turno agendado correctamente.'
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Error al agendar el turno.'
        };
      }
    }
    return {'success': false, 'message': 'Error de conexión con el servidor.'};
  }

  // --- SOLUCIÓN ROBUSTA DE CANCELACIÓN ---

  Future<Map<String, dynamic>> cancelConsultation({
    required int idReservaPaciente,
    required String motivo,
    required String fechaReserva,
    required String horaTurno,
  }) async {

    // 1. VALIDACIÓN LOCAL
    bool puedeCancelar = _canCancelConsultation(fechaReserva, horaTurno);

    if (!puedeCancelar) {
      return {
        'success': false,
        'message': 'Solo puede cancelar con al menos 6 horas de anticipación.'
      };
    }

    // 2. PREPARACIÓN DEL JSON
    final body = {
      'id_reserva_paciente': idReservaPaciente,
      'motivo': motivo,
    };

    try {
      // 3. LLAMADA A LA API
      final response = await ApiClient.put('/app/reservas/cancelar_reserva', body);

      if (response != null) {
        if (response['status'] == 'error' || response['success'] == false) {
          return {
            'success': false,
            'message': response['message'] ?? 'No se pudo cancelar la reserva'
          };
        }
        return {
          'success': true,
          'message': response['mensaje'] ?? 'Cancelado correctamente'
        };
      }
      return {'success': false, 'message': 'No se pudo conectar para cancelar'};

    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Lógica de validación de fecha corregida
  bool _canCancelConsultation(String fechaReserva, String horaTurno) {
    try {
      if (fechaReserva.trim().isEmpty || horaTurno.trim().isEmpty) return false;

      String fechaLimpia = fechaReserva.trim();
      DateTime? fechaParsed;

      // CASO A: Formato con GUIONES (-)
      if (fechaLimpia.contains('-')) {
        List<String> parts = fechaLimpia.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            fechaParsed = DateTime.parse(fechaLimpia);
          } else {
            String day = parts[0].padLeft(2, '0');
            String month = parts[1].padLeft(2, '0');
            String year = parts[2];
            if (year.length == 2) year = '20$year';
            String isoDate = '$year-$month-$day';
            fechaParsed = DateTime.parse(isoDate);
          }
        } else {
          return false;
        }
      }
      // CASO B: Formato con BARRAS (/)
      else if (fechaLimpia.contains('/')) {
        List<String> parts = fechaLimpia.split('/');
        if (parts.length == 3) {
          String day = parts[0].padLeft(2, '0');
          String month = parts[1].padLeft(2, '0');
          String year = parts[2];
          if (year.length == 2) year = '20$year';
          String isoDate = '$year-$month-$day';
          fechaParsed = DateTime.parse(isoDate);
        } else {
          return false;
        }
      }
      // CASO C: Formato desconocido
      else {
        try {
          fechaParsed = DateTime.parse(fechaLimpia);
        } catch (e) {
          return false;
        }
      }

      if (fechaParsed == null) return false;

      if (!horaTurno.contains(':')) return false;
      final horaParts = horaTurno.trim().split(':');
      if (horaParts.length < 2) return false;

      int hora = int.parse(horaParts[0]);
      int minuto = int.parse(horaParts[1]);

      final turnoDateTime = DateTime(
        fechaParsed.year,
        fechaParsed.month,
        fechaParsed.day,
        hora,
        minuto,
      );

      final now = DateTime.now();
      final difference = turnoDateTime.difference(now);

      if (difference.isNegative) return false;

      return difference.inHours >= 6;

    } catch (e) {
      return false;
    }
  }
}