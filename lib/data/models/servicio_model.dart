import 'package:flutter/material.dart';

class ServicioModel {
  final String id;         // serv_id
  final String nombre;     // serv_nombre
  final String? descripcion; // serv_descripcion
  final String? icono;     // serv_icono (nombre del icono como string)

  ServicioModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
  });

  factory ServicioModel.fromJson(Map<String, dynamic> json) {
    return ServicioModel(
      id: json['serv_id']?.toString() ?? '',
      nombre: json['serv_nombre'] as String? ?? '',
      descripcion: json['serv_descripcion'] as String?,
      icono: json['serv_icono'] as String?,
    );
  }

  /// Retorna el IconData según el nombre del icono guardado en DB
  IconData get iconData {
    switch (icono) {
      case 'vaccines':
        return Icons.vaccines_outlined;
      case 'shower':
        return Icons.shower_outlined;
      case 'content_cut':
        return Icons.content_cut_rounded;
      case 'screenshot_monitor':
        return Icons.screenshot_monitor_outlined;
      case 'medical_services':
      default:
        return Icons.medical_services_outlined;
    }
  }

  /// Color según el nombre del servicio
  Color get color {
    switch (nombre.toLowerCase()) {
      case 'vacunación':
        return const Color(0xFF7C6FCD);
      case 'baño y estética':
        return const Color(0xFFE58D57);
      case 'cirugía':
        return const Color(0xFFE53935);
      case 'radiografía y ecografía':
        return const Color(0xFF43B89C);
      case 'consulta veterinaria':
      default:
        return const Color(0xFF1CB5C9);
    }
  }
}

/// Representa la relación veterinario ↔ servicio con precio y duración
class VeterinarioServicioModel {
  final String id;           // vese_id
  final String veteId;       // vete_id
  final String servId;       // serv_id
  final double? precio;      // vese_precio
  final String? duracion;    // vese_duracion
  // Datos del veterinario (join)
  final String? nombre;      // usuarios.usua_nombre
  final String? especialidad;
  final int? experiencia;    // vete_experiencia
  final double? tarifa;      // vete_tarifa
  final String? fotoUrl;     // vete_foto_url
  final bool disponible;
  final double? latitud;     // vete_latitud
  final double? longitud;    // vete_longitud
  final String? direccion;   // vete_direccion

  VeterinarioServicioModel({
    required this.id,
    required this.veteId,
    required this.servId,
    this.precio,
    this.duracion,
    this.nombre,
    this.especialidad,
    this.experiencia,
    this.tarifa,
    this.fotoUrl,
    this.disponible = true,
    this.latitud,
    this.longitud,
    this.direccion,
  });

  factory VeterinarioServicioModel.fromJson(Map<String, dynamic> json) {
    final vet = json['veterinarios'] as Map<String, dynamic>?;
    final usuario = vet?['usuarios'] as Map<String, dynamic>?;
    // La foto viene de usua_foto_url (tabla usuarios), que es donde se guarda
    // al subir desde la app. vete_foto_url queda como fallback por compatibilidad.
    final fotoUrl = usuario?['usua_foto_url'] as String? ??
        vet?['vete_foto_url'] as String?;
    return VeterinarioServicioModel(
      id: json['vese_id']?.toString() ?? '',
      veteId: json['vete_id']?.toString() ?? '',
      servId: json['serv_id']?.toString() ?? '',
      precio: json['vese_precio'] != null
          ? double.tryParse(json['vese_precio'].toString())
          : null,
      duracion: json['vese_duracion'] as String?,
      nombre: usuario?['usua_nombre'] as String?,
      especialidad: vet?['vete_especialidad'] as String?,
      experiencia: vet?['vete_experiencia'] as int?,
      tarifa: vet?['vete_tarifa'] != null
          ? double.tryParse(vet!['vete_tarifa'].toString())
          : null,
      fotoUrl: fotoUrl,
      disponible: vet?['vete_disponible'] as bool? ?? true,
      latitud: vet?['vete_latitud'] != null
          ? double.tryParse(vet!['vete_latitud'].toString())
          : null,
      longitud: vet?['vete_longitud'] != null
          ? double.tryParse(vet!['vete_longitud'].toString())
          : null,
      direccion: vet?['vete_direccion'] as String?,
    );
  }
}
