class HistorialModel {
  final String id;           // hist_id
  final String? mascotaId;   // masc_id
  final String? veteId;      // vete_id
  final String? diagnostico; // hist_diagnostico
  final String? tratamiento; // hist_tratamiento
  final DateTime? fechaConsulta; // hist_fecha_consulta

  HistorialModel({
    required this.id,
    this.mascotaId,
    this.veteId,
    this.diagnostico,
    this.tratamiento,
    this.fechaConsulta,
  });

  factory HistorialModel.fromJson(Map<String, dynamic> json) {
    return HistorialModel(
      id: json['hist_id']?.toString() ?? '',
      mascotaId: json['masc_id']?.toString(),
      veteId: json['vete_id']?.toString(),
      diagnostico: json['hist_diagnostico'] as String?,
      tratamiento: json['hist_tratamiento'] as String?,
      fechaConsulta: json['hist_fecha_consulta'] != null
          ? DateTime.tryParse(json['hist_fecha_consulta'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      if (mascotaId != null && mascotaId!.isNotEmpty) 'masc_id': mascotaId,
      if (veteId != null && veteId!.isNotEmpty) 'vete_id': veteId,
      if (diagnostico != null && diagnostico!.isNotEmpty)
        'hist_diagnostico': diagnostico,
      if (tratamiento != null && tratamiento!.isNotEmpty)
        'hist_tratamiento': tratamiento,
      'hist_fecha_consulta':
          (fechaConsulta ?? DateTime.now()).toIso8601String().split('T').first,
    };
  }
}
