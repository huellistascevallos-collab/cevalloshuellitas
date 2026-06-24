class SolicitudAdopcionModel {
  final String id;          // soli_id
  final String usuaId;      // usua_id (solicitante)
  final String mascId;      // masc_id
  final DateTime fecha;     // soli_fecha
  /// soli_estado: Pendiente | Rechazada | Adoptado
  final String estado;

  // Campos adicionales del join con mascotas
  final String? mascotaNombre;
  final String? mascotaEspecie;
  final String? mascotaRaza;
  final String? mascotaFotoUrl;
  /// ID del dueño actual de la mascota (viene del join mascotas.usua_id)
  final String? duenioMascotaId;

  // Campos adicionales del join con usuarios (solicitante)
  final String? usuarioNombre;
  final String? usuarioCorreo;
  final String? usuarioTelefono;
  final String? usuarioFotoUrl;

  SolicitudAdopcionModel({
    required this.id,
    required this.usuaId,
    required this.mascId,
    required this.fecha,
    this.estado = 'Pendiente',
    this.mascotaNombre,
    this.mascotaEspecie,
    this.mascotaRaza,
    this.mascotaFotoUrl,
    this.duenioMascotaId,
    this.usuarioNombre,
    this.usuarioCorreo,
    this.usuarioTelefono,
    this.usuarioFotoUrl,
  });

  factory SolicitudAdopcionModel.fromJson(Map<String, dynamic> json) {
    final mascota = json['mascotas'] as Map<String, dynamic>?;
    final usuario = json['usuarios'] as Map<String, dynamic>?;

    return SolicitudAdopcionModel(
      id: json['soli_id']?.toString() ?? '',
      usuaId: json['usua_id']?.toString() ?? '',
      mascId: json['masc_id']?.toString() ?? '',
      fecha: json['soli_fecha'] != null
          ? DateTime.tryParse(json['soli_fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estado: json['soli_estado']?.toString() ?? 'Pendiente',
      mascotaNombre: mascota?['masc_nombre'] as String?,
      mascotaEspecie: mascota?['masc_especie'] as String?,
      mascotaRaza: mascota?['masc_raza'] as String?,
      mascotaFotoUrl: mascota?['masc_foto_url'] as String?,
      duenioMascotaId: mascota?['usua_id']?.toString(),
      usuarioNombre: usuario?['usua_nombre'] as String?,
      usuarioCorreo: usuario?['usua_correo'] as String?,
      usuarioTelefono: usuario?['usua_telefono'] as String?,
      usuarioFotoUrl: usuario?['usua_foto_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'usua_id': usuaId,
      'masc_id': mascId,
      'soli_estado': estado,
    };
  }

  SolicitudAdopcionModel copyWith({String? estado}) {
    return SolicitudAdopcionModel(
      id: id,
      usuaId: usuaId,
      mascId: mascId,
      fecha: fecha,
      estado: estado ?? this.estado,
      mascotaNombre: mascotaNombre,
      mascotaEspecie: mascotaEspecie,
      mascotaRaza: mascotaRaza,
      mascotaFotoUrl: mascotaFotoUrl,
      duenioMascotaId: duenioMascotaId,
      usuarioNombre: usuarioNombre,
      usuarioCorreo: usuarioCorreo,
      usuarioTelefono: usuarioTelefono,
      usuarioFotoUrl: usuarioFotoUrl,
    );
  }
}
