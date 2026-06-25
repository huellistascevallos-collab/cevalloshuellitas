import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solicitud_rol_model.dart';

/// Gestiona las solicitudes de cambio de rol a 'veterinario'.
/// Requiere que exista la tabla `solicitudes_rol` en Supabase con:
///   srol_id uuid PK default gen_random_uuid()
///   usua_id uuid FK → usuarios(usua_id)
///   srol_estado text default 'pendiente'
///   srol_fecha timestamptz default now()
class SolicitudRolService {
  final SupabaseClient _client = Supabase.instance.client;

  static const _selectJoin =
      '*, usuarios(usua_nombre, usua_correo, usua_foto_url, usua_telefono)';

  /// Envía una solicitud de cambio de rol.
  /// Lanza excepción si ya tiene una solicitud pendiente.
  Future<SolicitudRolModel> enviarSolicitud(String usuaId) async {
    // Verificar si ya tiene una solicitud pendiente
    final existente = await _client
        .from('solicitudes_rol')
        .select('srol_id, srol_estado')
        .eq('usua_id', usuaId)
        .eq('srol_estado', 'pendiente')
        .maybeSingle();

    if (existente != null) {
      throw Exception(
          'Ya tienes una solicitud pendiente. Espera la respuesta del administrador.');
    }

    final inserted = await _client
        .from('solicitudes_rol')
        .insert({'usua_id': usuaId, 'srol_estado': 'pendiente'})
        .select(_selectJoin)
        .single();

    return SolicitudRolModel.fromJson(inserted);
  }

  /// Devuelve la solicitud activa (pendiente) del usuario, o null.
  Future<SolicitudRolModel?> obtenerSolicitudActiva(String usuaId) async {
    try {
      final row = await _client
          .from('solicitudes_rol')
          .select(_selectJoin)
          .eq('usua_id', usuaId)
          .order('srol_fecha', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return SolicitudRolModel.fromJson(row);
    } catch (e) {
      debugPrint('SolicitudRolService.obtenerSolicitudActiva: $e');
      return null;
    }
  }

  /// Devuelve todas las solicitudes (para el admin).
  Future<List<SolicitudRolModel>> obtenerTodas() async {
    try {
      final rows = await _client
          .from('solicitudes_rol')
          .select(_selectJoin)
          .order('srol_fecha', ascending: false);
      return (rows as List)
          .map((e) => SolicitudRolModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('SolicitudRolService.obtenerTodas: $e');
      return [];
    }
  }

  /// Devuelve solo las solicitudes pendientes (para el admin).
  Future<List<SolicitudRolModel>> obtenerPendientes() async {
    try {
      final rows = await _client
          .from('solicitudes_rol')
          .select(_selectJoin)
          .eq('srol_estado', 'pendiente')
          .order('srol_fecha', ascending: false);
      return (rows as List)
          .map((e) => SolicitudRolModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('SolicitudRolService.obtenerPendientes: $e');
      return [];
    }
  }

  /// Aprueba la solicitud: cambia el estado, crea el perfil veterinario
  /// (si no existe) y actualiza el rol del usuario.
  Future<void> aprobar(SolicitudRolModel solicitud) async {
    // 1. Marcar solicitud como aprobada
    await _client
        .from('solicitudes_rol')
        .update({'srol_estado': 'aprobada'})
        .eq('srol_id', solicitud.id);

    // 2. Crear fila en veterinarios si no existe (disponible=false)
    final existeVet = await _client
        .from('veterinarios')
        .select('vete_id')
        .eq('usua_id', solicitud.usuaId)
        .maybeSingle();

    if (existeVet == null) {
      await _client.from('veterinarios').insert({
        'usua_id': solicitud.usuaId,
        'vete_disponible': false,
      });
    }

    // 3. Actualizar rol del usuario
    await _client
        .from('usuarios')
        .update({'usua_rol': 'veterinario'})
        .eq('usua_id', solicitud.usuaId);
  }

  /// Rechaza la solicitud.
  Future<void> rechazar(String srolId) async {
    await _client
        .from('solicitudes_rol')
        .update({'srol_estado': 'rechazada'})
        .eq('srol_id', srolId);
  }

  /// Elimina una solicitud (acción admin).
  Future<void> eliminar(String srolId) async {
    await _client
        .from('solicitudes_rol')
        .delete()
        .eq('srol_id', srolId);
  }

  /// Devuelve el conteo de solicitudes pendientes.
  Future<int> contarPendientes() async {
    try {
      final rows = await _client
          .from('solicitudes_rol')
          .select('srol_id')
          .eq('srol_estado', 'pendiente');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }
}
