import 'package:flutter/material.dart';

class MascotaModel {
  final String id;         // masc_id
  final String usuarioId;  // usua_id (dueño) — puede estar vacío si no aplica
  final String nombre;     // masc_nombre
  final String especie;    // masc_especie
  final String raza;       // masc_raza
  final String genero;     // masc_sexo
  final String edad;       // masc_edad (INTEGER en DB, guardamos como String)
  final String estado;     // masc_estado
  final String? descripcion; // masc_descripcion
  final String? fotoUrl;     // masc_foto_url
  final DateTime? createdAt; // created_at — fecha de registro en la DB
  // Datos del propietario (solo disponibles cuando se hace join con usuarios)
  final String? propietarioNombre;
  final String? propietarioTelefono;
  final String? propietarioFotoUrl; // usua_foto_url via join

  MascotaModel({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.genero,
    required this.edad,
    this.estado = 'Disponible',
    this.descripcion,
    this.fotoUrl,
    this.createdAt,
    this.propietarioNombre,
    this.propietarioTelefono,
    this.propietarioFotoUrl,
  });

  factory MascotaModel.fromJson(Map<String, dynamic> json) {
    // El join con usuarios puede venir como un objeto anidado
    final usuariosJoin = json['usuarios'] as Map<String, dynamic>?;

    return MascotaModel(
      id: json['masc_id']?.toString() ?? '',
      usuarioId: json['usua_id']?.toString() ?? '',
      nombre: json['masc_nombre'] as String? ?? '',
      especie: json['masc_especie'] as String? ?? '',
      raza: json['masc_raza'] as String? ?? '',
      genero: json['masc_sexo'] as String? ?? '',
      edad: json['masc_edad']?.toString() ?? '',
      estado: json['masc_estado'] as String? ?? 'Disponible',
      descripcion: json['masc_descripcion'] as String?,
      fotoUrl: json['masc_foto_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      propietarioNombre: usuariosJoin?['usua_nombre'] as String?,
      propietarioTelefono: usuariosJoin?['usua_telefono'] as String?,
      propietarioFotoUrl: usuariosJoin?['usua_foto_url'] as String?,
    );
  }

  /// Para INSERT — nunca incluye masc_id
  Map<String, dynamic> toInsertJson() {
    return {
      if (usuarioId.isNotEmpty) 'usua_id': usuarioId,
      'masc_nombre': nombre,
      if (especie.isNotEmpty) 'masc_especie': especie,
      if (raza.isNotEmpty) 'masc_raza': raza,
      'masc_edad': int.tryParse(edad) ?? 0,
      if (genero.isNotEmpty) 'masc_sexo': genero,
      if (descripcion != null && descripcion!.isNotEmpty)
        'masc_descripcion': descripcion,
      if (fotoUrl != null && fotoUrl!.isNotEmpty) 'masc_foto_url': fotoUrl,
      'masc_estado': estado,
    };
  }

  /// Para UPDATE
  Map<String, dynamic> toUpdateJson() {
    return {
      'masc_nombre': nombre,
      'masc_especie': especie.isNotEmpty ? especie : null,
      'masc_raza': raza.isNotEmpty ? raza : null,
      'masc_edad': int.tryParse(edad) ?? 0,
      'masc_sexo': genero.isNotEmpty ? genero : null,
      'masc_descripcion':
          descripcion?.isNotEmpty == true ? descripcion : null,
      'masc_foto_url': fotoUrl?.isNotEmpty == true ? fotoUrl : null,
      'masc_estado': estado,
    };
  }

  IconData get icon {
    final e = especie.toLowerCase();
    if (e.contains('perro')) return Icons.pets;
    if (e.contains('gato')) return Icons.catching_pokemon;
    if (e.contains('ave') || e.contains('pájaro')) return Icons.flutter_dash;
    if (e.contains('conejo')) return Icons.cruelty_free;
    return Icons.pets;
  }

  Color get color {
    final e = especie.toLowerCase();
    if (e.contains('perro')) return const Color(0xFF1CB5C9);
    if (e.contains('gato')) return const Color(0xFFE58D57);
    if (e.contains('ave') || e.contains('pájaro')) return const Color(0xFF7C6FCD);
    if (e.contains('conejo')) return const Color(0xFF43B89C);
    return const Color(0xFF1CB5C9);
  }
}
