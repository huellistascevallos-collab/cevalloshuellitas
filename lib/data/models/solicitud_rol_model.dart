/// Modelo para solicitudes de cambio de rol a 'veterinario'.
/// Tabla: solicitudes_rol
/// Columnas: srol_id, usua_id, srol_estado (pendiente/aprobada/rechazada), srol_fecha
class SolicitudRolModel {
  final String id;        // srol_id
  final String usuaId;    // usua_id
  final DateTime fecha;   // srol_fecha
  final String estado;    // pendiente | aprobada | rechazada

  // Datos del usuario (join con usuarios)
  final String? usuarioNombre;
  final String? usuarioCorreo;
  final String? usuarioFotoUrl;
  final String? usuarioTelefono;

  SolicitudRolModel({
    required this.id,
    required this.usuaId,
    required this.fecha,
    this.estado = 'pendiente',
    this.usuarioNombre,
    this.usuarioCorreo,
    this.usuarioFotoUrl,
    this.usuarioTelefono,
  });

  factory SolicitudRolModel.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuarios'] as Map<String, dynamic>?;
    return SolicitudRolModel(
      id: json['srol_id']?.toString() ?? '',
      usuaId: json['usua_id']?.toString() ?? '',
      fecha: json['srol_fecha'] != null
          ? DateTime.tryParse(json['srol_fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estado: json['srol_estado']?.toString() ?? 'pendiente',
      usuarioNombre: usuario?['usua_nombre'] as String?,
      usuarioCorreo: usuario?['usua_correo'] as String?,
      usuarioFotoUrl: usuario?['usua_foto_url'] as String?,
      usuarioTelefono: usuario?['usua_telefono'] as String?,
    );
  }
}
