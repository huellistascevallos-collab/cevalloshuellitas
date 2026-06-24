/// Tipos de notificación in-app
enum TipoNotificacion {
  nuevaCita,           // Vet recibe nueva solicitud de cita
  citaConfirmada,      // Usuario: su cita fue confirmada
  citaRechazada,       // Usuario: su cita fue rechazada
  recordatorio30min,   // 30 minutos antes de la cita
  recordatorioAhora,   // A la hora exacta de la cita
  solicitudAdopcion,   // Dueño: alguien quiere adoptar su mascota
}

/// Prioridad visual de la notificación
enum PrioridadNotificacion { alta, media, baja }

class NotificacionModel {
  final String id;
  final TipoNotificacion tipo;
  final String titulo;
  final String cuerpo;
  final String? citaId;
  final String? mascotaNombre;
  final String? fecha;
  final String? hora;
  final DateTime creadaEn;
  bool leida;

  // ── Datos del solicitante (para solicitudAdopcion y nuevaCita) ─────────────
  final String? solicitanteId;
  final String? solicitanteNombre;
  final String? solicitanteCorreo;
  final String? solicitanteTelefono;
  final String? solicitanteFotoUrl;

  NotificacionModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.cuerpo,
    this.citaId,
    this.mascotaNombre,
    this.fecha,
    this.hora,
    DateTime? creadaEn,
    this.leida = false,
    this.solicitanteId,
    this.solicitanteNombre,
    this.solicitanteCorreo,
    this.solicitanteTelefono,
    this.solicitanteFotoUrl,
  }) : creadaEn = creadaEn ?? DateTime.now();

  // ── Color por tipo ─────────────────────────────────────────────────────────
  static const Map<TipoNotificacion, int> _colorMap = {
    TipoNotificacion.nuevaCita:          0xFFE58D57,  // naranja
    TipoNotificacion.citaConfirmada:     0xFF43B89C,  // verde
    TipoNotificacion.citaRechazada:      0xFFE53935,  // rojo
    TipoNotificacion.recordatorio30min:  0xFF1CB5C9,  // teal
    TipoNotificacion.recordatorioAhora:  0xFF7C6FCD,  // purple
    TipoNotificacion.solicitudAdopcion:  0xFFE58D57,  // naranja
  };

  // ── Prioridad por tipo ─────────────────────────────────────────────────────
  static const Map<TipoNotificacion, PrioridadNotificacion> _prioridadMap = {
    TipoNotificacion.recordatorioAhora:  PrioridadNotificacion.alta,
    TipoNotificacion.citaRechazada:      PrioridadNotificacion.alta,
    TipoNotificacion.recordatorio30min:  PrioridadNotificacion.media,
    TipoNotificacion.citaConfirmada:     PrioridadNotificacion.media,
    TipoNotificacion.nuevaCita:          PrioridadNotificacion.baja,
    TipoNotificacion.solicitudAdopcion:  PrioridadNotificacion.media,
  };

  int get colorValue => _colorMap[tipo] ?? 0xFF1CB5C9;
  PrioridadNotificacion get prioridad =>
      _prioridadMap[tipo] ?? PrioridadNotificacion.baja;

  /// ¿Tiene datos de solicitante para mostrar perfil?
  bool get tieneSolicitante =>
      solicitanteId != null && solicitanteId!.isNotEmpty;

  /// Tiempo relativo legible
  String get tiempoRelativo {
    final diff = DateTime.now().difference(creadaEn);
    if (diff.inSeconds < 60) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return '${creadaEn.day}/${creadaEn.month}/${creadaEn.year}';
  }

  /// Etiqueta de categoría para agrupar en tabs
  String get categoria {
    switch (tipo) {
      case TipoNotificacion.nuevaCita:
        return 'Solicitudes';
      case TipoNotificacion.solicitudAdopcion:
        return 'Solicitudes';
      case TipoNotificacion.citaConfirmada:
      case TipoNotificacion.citaRechazada:
        return 'Confirmaciones';
      case TipoNotificacion.recordatorio30min:
      case TipoNotificacion.recordatorioAhora:
        return 'Recordatorios';
    }
  }
}
