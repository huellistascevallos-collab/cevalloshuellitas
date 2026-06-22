class VeterinarioModel {
  final String id;        // vete_id
  final String usuarioId; // usua_id
  final String? especialidad;  // vete_especialidad
  final int? experiencia;      // vete_experiencia (años)
  final double? tarifa;        // vete_tarifa
  final String? fotoUrl;       // vete_foto_url
  final bool disponible;       // vete_disponible

  VeterinarioModel({
    required this.id,
    required this.usuarioId,
    this.especialidad,
    this.experiencia,
    this.tarifa,
    this.fotoUrl,
    this.disponible = true,
  });

  factory VeterinarioModel.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuarios'] as Map<String, dynamic>?;
    // La foto real viene de usua_foto_url (tabla usuarios).
    // vete_foto_url queda como fallback por compatibilidad.
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
    };
  }

  /// Para UPDATE — solo campos editables
  Map<String, dynamic> toUpdateJson() {
    return {
      'vete_especialidad':
          especialidad?.isNotEmpty == true ? especialidad : null,
      'vete_experiencia': experiencia,
      'vete_tarifa': tarifa,
      'vete_foto_url': fotoUrl?.isNotEmpty == true ? fotoUrl : null,
      'vete_disponible': disponible,
    };
  }

  VeterinarioModel copyWith({
    String? especialidad,
    int? experiencia,
    double? tarifa,
    String? fotoUrl,
    bool? disponible,
  }) {
    return VeterinarioModel(
      id: id,
      usuarioId: usuarioId,
      especialidad: especialidad ?? this.especialidad,
      experiencia: experiencia ?? this.experiencia,
      tarifa: tarifa ?? this.tarifa,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      disponible: disponible ?? this.disponible,
    );
  }
}
