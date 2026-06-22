import 'package:flutter/material.dart';

class MascotaModel {
  final String id;
  final String usuarioId;
  final String nombre;
  final String especie;
  final String raza;
  final String genero;
  final String edad;
  final String estado;
  final String? descripcion;
  final String? fotoUrl;

  MascotaModel({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.genero,
    required this.edad,
    this.estado = 'propio', // Valor por defecto
    this.descripcion,
    this.fotoUrl,
  });

  /// Crea una instancia de [MascotaModel] a partir de un mapa JSON
  /// que proviene de la tabla `mascotas` en Supabase.
  factory MascotaModel.fromJson(Map<String, dynamic> json) {
    return MascotaModel(
      id: json['masc_id']?.toString() ?? '',
      usuarioId: json['usua_id']?.toString() ?? '',
      nombre: json['masc_nombre'] as String? ?? '',
      especie: json['masc_especie'] as String? ?? '',
      raza: json['masc_raza'] as String? ?? '',
      genero: json['masc_sexo'] as String? ?? '', // Corregido a masc_sexo
      edad: json['masc_edad']?.toString() ?? '', // Parseado desde int
      estado: json['masc_estado'] as String? ?? 'propio',
      descripcion: json['masc_descripcion'] as String?,
      fotoUrl: json['masc_foto_url'] as String?,
    );
  }

  /// Convierte la instancia a un mapa JSON compatible con la tabla `mascotas`.
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'masc_id': id,
      'usua_id': usuarioId, // AVISO: Asegúrate de que esta columna exista en tu DB
      'masc_nombre': nombre,
      'masc_especie': especie,
      'masc_raza': raza,
      'masc_sexo': genero, // Corregido a masc_sexo
      'masc_edad': int.tryParse(edad) ?? 0, // Convertido a INTEGER
      'masc_estado': estado,
      if (descripcion != null) 'masc_descripcion': descripcion,
      if (fotoUrl != null) 'masc_foto_url': fotoUrl,
    };
  }

  /// Retorna un IconData representativo según la especie
  IconData get icon {
    final especieLower = especie.toLowerCase();
    if (especieLower.contains('perro')) return Icons.pets;
    if (especieLower.contains('gato')) return Icons.catching_pokemon;
    if (especieLower.contains('ave')) return Icons.flutter_dash;
    if (especieLower.contains('conejo')) return Icons.cruelty_free;
    return Icons.pets;
  }

  /// Retorna un Color representativo según la especie
  Color get color {
    final especieLower = especie.toLowerCase();
    if (especieLower.contains('perro')) return const Color(0xFF1CB5C9);
    if (especieLower.contains('gato')) return const Color(0xFFE58D57);
    if (especieLower.contains('ave')) return const Color(0xFF7C6FCD);
    if (especieLower.contains('conejo')) return const Color(0xFF43B89C);
    return const Color(0xFF1CB5C9);
  }
}
