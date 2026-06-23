class VeterinarioModel {
  final String id;        // vete_id
  final String usuarioId; // usua_id
  final String? especialidad;  // vete_especialidad
  final int? experiencia;      // vete_experiencia (años)
  final double? tarifa;        // vete_tarifa
  final String? fotoUrl;       // usua_foto_url (via join)
  final bool disponible;       // vete_disponible
  final double? latitud;       // vete_latitud
  final double? longitud;      // vete_longitud
  final String? direccion;     // vete_direccion

  VeterinarioModel({
    required this.id,
    required this.usuarioId,
    this.especialidad,
    this.experiencia,
    this.tarifa,
    this.fotoUrl,
    this.disponible = true,
    this.latitud,
    this.longitud,
    this.direccion,
  });

  factory VeterinarioModel.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuarios'] as Map<String, dynamic>?;
    final fotoUrl = usuario?['usua_foto_url'] as String? ??
        json['vete_foto_url'] as String?;
    return VeterinarioModel(
      id: json['vete_id']?.toString() ?? '',
      usuarioId: json['usua_id']?.toString() ?? '',
      especialidad: json['vete_especialidad'] as String?,
      experiencia: json['vete_experiencia'] as int?,
      tarifa: json['vete_tarifa'] != null
          ? double.tryParse(json['vete_tarifa'].toString())
          : null,
      fotoUrl: fotoUrl,
      disponible: json['vete_disponible'] as bool? ?? true,
      latitud: json['vete_latitud'] != null
          ? double.tryParse(json['vete_latitud'].toString())
          : null,
      longitud: json['vete_longitud'] != null
          ? double.tryParse(json['vete_longitud'].toString())
          : null,
      direccion: json['vete_direccion'] as String?,
    );
  }

  /// Para INSERT — nunca incluye vete_id (auto-generado por Supabase)
  Map<String, dynamic> toInsertJson() {
    return {
      'usua_id': usuarioId,
      if (especialidad != null && especialidad!.isNotEmpty)
        'vete_especialidad': especialidad,
      if (experiencia != null) 'vete_experiencia': experiencia,
      if (tarifa != null) 'vete_tarifa': tarifa,
      if (fotoUrl != null && fotoUrl!.isNotEmpty) 'vete_foto_url': fotoUrl,
      'vete_disponible': disponible,
      if (latitud != null) 'vete_latitud': latitud,
      if (longitud != null) 'vete_longitud': longitud,
      if (direccion != null && direccion!.isNotEmpty) 'vete_direccion': direccion,
    };
  }

  /// Para UPDATE — solo campos editables
  Map<String, dynamic> toUpdateJson() {
    return {
      'vete_especialidad': especialidad?.isNotEmpty == true ? especialidad : null,
      'vete_experiencia': experiencia,
      'vete_tarifa': tarifa,
      'vete_foto_url': fotoUrl?.isNotEmpty == true ? fotoUrl : null,
      'vete_disponible': disponible,
      'vete_latitud': latitud,
      'vete_longitud': longitud,
      'vete_direccion': direccion?.isNotEmpty == true ? direccion : null,
    };
  }

  VeterinarioModel copyWith({
    String? especialidad,
    int? experiencia,
    double? tarifa,
    String? fotoUrl,
    bool? disponible,
    double? latitud,
    double? longitud,
    String? direccion,
  }) {
    return VeterinarioModel(
      id: id,
      usuarioId: usuarioId,
      especialidad: especialidad ?? this.especialidad,
      experiencia: experiencia ?? this.experiencia,
      tarifa: tarifa ?? this.tarifa,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      disponible: disponible ?? this.disponible,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccion: direccion ?? this.direccion,
    );
  }
}
