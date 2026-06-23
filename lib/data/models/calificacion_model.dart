class CalificacionModel {
  final String id;          // cali_id
  final String usuaId;      // usua_id
  final String veteId;      // vete_id
  final int puntuacion;     // cali_puntuacion (1-5)
  final String? comentario; // cali_comentario
  final DateTime? fecha;    // cali_fecha

  CalificacionModel({
    required this.id,
    required this.usuaId,
    required this.veteId,
    required this.puntuacion,
    this.comentario,
    this.fecha,
  });

  factory CalificacionModel.fromJson(Map<String, dynamic> json) {
    return CalificacionModel(
      id: json['cali_id']?.toString() ?? '',
      usuaId: json['usua_id']?.toString() ?? '',
      veteId: json['vete_id']?.toString() ?? '',
      puntuacion: json['cali_puntuacion'] as int? ?? 0,
      comentario: json['cali_comentario'] as String?,
      fecha: json['cali_fecha'] != null
          ? DateTime.tryParse(json['cali_fecha'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'usua_id': usuaId,
      'vete_id': veteId,
      'cali_puntuacion': puntuacion,
      if (comentario != null && comentario!.isNotEmpty)
        'cali_comentario': comentario,
    };
  }
}
