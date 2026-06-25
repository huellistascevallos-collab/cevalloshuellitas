import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';
import '../models/veterinario_model.dart';

/// Servicio exclusivo para el rol administrador.
/// Permite leer, editar y eliminar usuarios y veterinarios.
class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Usuarios ─────────────────────────────────────────────────────────────

  /// Devuelve todos los usuarios registrados ordenados por fecha de registro.
  Future<List<UsuarioModel>> obtenerTodosLosUsuarios() async {
    try {
      final response = await _client
          .from('usuarios')
          .select()
          .order('usua_fecha_registro', ascending: false);
      return (response as List)
          .map((e) => UsuarioModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('AdminService.obtenerTodosLosUsuarios: $e');
      return [];
    }
  }

  /// Cambia el rol de un usuario.
  Future<void> cambiarRolUsuario(String usuaId, String nuevoRol) async {
    await _client
        .from('usuarios')
        .update({'usua_rol': nuevoRol})
        .eq('usua_id', usuaId);
  }

  /// Elimina el perfil del usuario de la tabla `usuarios`.
  /// No elimina la cuenta de Supabase Auth (requiere service_role key).
  Future<void> eliminarUsuario(String usuaId) async {
    await _client.from('usuarios').delete().eq('usua_id', usuaId);
  }

  // ── Veterinarios ──────────────────────────────────────────────────────────

  /// Devuelve todos los veterinarios con datos del usuario asociado.
  Future<List<VeterinarioModel>> obtenerTodosLosVeterinarios() async {
    try {
      final response = await _client
          .from('veterinarios')
          .select('*, usuarios(usua_nombre, usua_correo, usua_foto_url, usua_telefono)')
          .order('vete_id');
      return (response as List)
          .map((e) => VeterinarioModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('AdminService.obtenerTodosLosVeterinarios: $e');
      return [];
    }
  }

  /// Activa o desactiva la disponibilidad de un veterinario.
  Future<void> toggleDisponibilidadVeterinario(
      String veteId, bool disponible) async {
    await _client
        .from('veterinarios')
        .update({'vete_disponible': disponible})
        .eq('vete_id', veteId);
  }

  /// Elimina el perfil veterinario (tabla veterinarios) y cambia el rol
  /// del usuario a 'usuario'.
  Future<void> eliminarVeterinario(String veteId, String usuaId) async {
    await _client.from('veterinarios').delete().eq('vete_id', veteId);
    await _client
        .from('usuarios')
        .update({'usua_rol': 'usuario'})
        .eq('usua_id', usuaId);
  }

  // ── Estadísticas rápidas ──────────────────────────────────────────────────

  Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      final usuarios = await _client
          .from('usuarios')
          .select('usua_id, usua_rol');
      final mascotas = await _client.from('mascotas').select('masc_id');
      final citas = await _client.from('citas').select('cita_id');
      final adopciones = await _client
          .from('solicitudes_adopcion')
          .select('soli_id');

      final totalUsuarios =
          (usuarios as List).where((u) => u['usua_rol'] == 'usuario').length;
      final totalVeterinarios =
          (usuarios).where((u) => u['usua_rol'] == 'veterinario').length;

      return {
        'usuarios': totalUsuarios,
        'veterinarios': totalVeterinarios,
        'mascotas': (mascotas as List).length,
        'citas': (citas as List).length,
        'adopciones': (adopciones as List).length,
      };
    } catch (e) {
      debugPrint('AdminService.obtenerEstadisticas: $e');
      return {
        'usuarios': 0,
        'veterinarios': 0,
        'mascotas': 0,
        'citas': 0,
        'adopciones': 0,
      };
    }
  }
}
