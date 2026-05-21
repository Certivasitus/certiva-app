import '../models/user.dart' as app_user;

/// Resultado detallado al cargar un cliente (útil para depuración en release).
class ClientLoadResult {
  final app_user.User? user;
  final String? failureStep;
  final String? failureDetail;
  final int? clientIdUsed;
  final Map<String, dynamic>? lastApiPayload;
  /// true si entró sin prepaga en lab; debe completarse en Mi Perfil.
  final bool requiresPrepagaSetup;

  const ClientLoadResult({
    this.user,
    this.failureStep,
    this.failureDetail,
    this.clientIdUsed,
    this.lastApiPayload,
    this.requiresPrepagaSetup = false,
  });

  bool get isSuccess => user != null;

  String get debugMessage {
    if (isSuccess) return 'OK';
    final step = failureStep ?? 'desconocido';
    final detail = failureDetail ?? 'sin detalle';
    final id = clientIdUsed != null ? ' | id=$clientIdUsed' : '';
    return '$step: $detail$id';
  }
}
