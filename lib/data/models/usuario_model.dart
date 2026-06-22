class UsuarioModel {
  final String id;
  final String nombre;
  final String correo;
  final String? telefono;
  final String rol;
  final DateTime? fechaRegistro;
  final String? fotoUrl; // usua_foto_url

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.telefono,
    required this.rol,
    this.fechaRegistro,
    this.fotoUrl,
  });

  /// Crea una instancia de [UsuarioModel] a partir de un mapa JSON
  /// que proviene de la tabla `usuarios` en Supabase.
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['usua_id'] as String,
      nombre: json['usua_nombre'] as String,
      correo: json['usua_correo'] as String,
      telefono: json['usua_telefono'] as String?,
      rol: json['usua_rol'] as String,
      fechaRegistro: json['usua_fecha_registro'] != null
          ? DateTime.parse(json['usua_fecha_registro'] as String)
          : null,
      fotoUrl: json['usua_foto_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usua_id': id,
      'usua_nombre': nombre,
      'usua_correo': correo,
      'usua_telefono': telefono,
      'usua_rol': rol,
      if (fotoUrl != null) 'usua_foto_url': fotoUrl,
    };
  }
}
