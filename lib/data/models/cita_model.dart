class CitaModel {
  final String id;              // cita_id
  final String usuarioId;       // usua_id (dueño de la mascota)
  final String? veteId;         // vete_id
  final String? mascotaId;      // masc_id
  final String mascotaNombre;   // se obtiene por join o se guarda aparte
  final String propietarioNombre;
  final String motivo;          // cita_motivo
  final String fecha;           // cita_fecha (ISO string)
  final String hora;            // extraída de cita_fecha
  final String estado;          // cita_estado
  final String? direccion;      // cita_direccion
  final String? descripcion;    // cita_descripcion (notas del veterinario)
  final String? receta;         // cita_receta (prescripción)

  CitaModel({
    required this.id,
    required this.usuarioId,
    this.veteId,
    this.mascotaId,
    required this.mascotaNombre,
    required this.propietarioNombre,
    required this.motivo,
    required this.fecha,
    required this.hora,
    this.estado = 'pendiente',
    this.direccion,
    this.descripcion,
    this.receta,
  });

  factory CitaModel.fromJson(Map<String, dynamic> json) {
    // cita_fecha viene como ISO timestamp: "2025-06-22T10:00:00"
    final fechaRaw = json['cita_fecha']?.toString() ?? '';
    String fechaStr = '';
    String horaStr = '';
    if (fechaRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(fechaRaw);
        fechaStr =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        horaStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        fechaStr = fechaRaw;
      }
    }

    // Nombre mascota: puede venir de join (mascotas.masc_nombre)
    // o de columna directa masc_nombre (citas de veterinario creadas manualmente)
    final mascotasJoin = json['mascotas'] as Map<String, dynamic>?;
    final mascotaNombre = mascotasJoin?['masc_nombre'] as String? ??
        json['masc_nombre'] as String? ??
        'Mascota';

    // Nombre propietario: puede venir de join (usuarios.usua_nombre)
    // o de columna directa propietario_nombre
    final usuariosJoin = json['usuarios'] as Map<String, dynamic>?;
    final propietarioNombre = usuariosJoin?['usua_nombre'] as String? ??
        json['propietario_nombre'] as String? ??
        '';

    return CitaModel(
      id: json['cita_id']?.toString() ?? '',
      usuarioId: json['usua_id']?.toString() ?? '',
      veteId: json['vete_id']?.toString(),
      mascotaId: json['masc_id']?.toString(),
      mascotaNombre: mascotaNombre,
      propietarioNombre: propietarioNombre,
      motivo: json['cita_motivo'] as String? ?? '',
      fecha: fechaStr,
      hora: horaStr,
      estado: json['cita_estado'] as String? ?? 'pendiente',
      direccion: json['cita_direccion'] as String?,
      descripcion: json['cita_descripcion'] as String?,
      receta: json['cita_receta'] as String?,
    );
  }

  /// Para INSERT — combina fecha + hora en un timestamp ISO
  Map<String, dynamic> toInsertJson() {
    return {
      if (usuarioId.isNotEmpty) 'usua_id': usuarioId,
      if (veteId != null && veteId!.isNotEmpty) 'vete_id': veteId,
      if (mascotaId != null && mascotaId!.isNotEmpty) 'masc_id': mascotaId,
      'cita_fecha': '${fecha}T${hora.isNotEmpty ? hora : '00:00'}:00',
      if (direccion != null && direccion!.isNotEmpty)
        'cita_direccion': direccion,
      'cita_motivo': motivo,
      'cita_estado': estado,
    };
  }

  CitaModel copyWith({String? estado, String? direccion, String? descripcion, String? receta}) {
    return CitaModel(
      id: id,
      usuarioId: usuarioId,
      veteId: veteId,
      mascotaId: mascotaId,
      mascotaNombre: mascotaNombre,
      propietarioNombre: propietarioNombre,
      motivo: motivo,
      fecha: fecha,
      hora: hora,
      estado: estado ?? this.estado,
      direccion: direccion ?? this.direccion,
      descripcion: descripcion ?? this.descripcion,
      receta: receta ?? this.receta,
    );
  }
}
