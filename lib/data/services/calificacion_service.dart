import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calificacion_model.dart';
import '../models/historial_model.dart';

class CalificacionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Guarda la calificación del usuario al veterinario.
  Future<CalificacionModel> guardarCalificacion(
      CalificacionModel calificacion) async {
    final response = await _client
        .from('calificaciones')
        .insert(calificacion.toInsertJson())
        .select()
        .single();
    return CalificacionModel.fromJson(response);
  }

  /// Verifica si un usuario ya calificó a un veterinario.
  Future<bool> yaCalificado({
    required String usuaId,
    required String veteId,
  }) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select('cali_id')
          .eq('usua_id', usuaId)
          .eq('vete_id', veteId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error verificando calificación: $e');
      return false;
    }
  }

  /// Obtiene la calificación de un usuario a un veterinario.
  Future<CalificacionModel?> obtenerCalificacion({
    required String usuaId,
    required String veteId,
  }) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select()
          .eq('usua_id', usuaId)
          .eq('vete_id', veteId)
          .maybeSingle();
      if (response == null) return null;
      return CalificacionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error obteniendo calificación: $e');
      return null;
    }
  }

  /// Obtiene el promedio de puntuación de un veterinario.
  Future<double> obtenerPromedio(String veteId) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select('cali_puntuacion')
          .eq('vete_id', veteId);
      final lista = response as List;
      if (lista.isEmpty) return 0.0;
      final suma = lista.fold<int>(
          0, (acc, e) => acc + (e['cali_puntuacion'] as int? ?? 0));
      return suma / lista.length;
    } catch (e) {
      debugPrint('Error obteniendo promedio: $e');
      return 0.0;
    }
  }

  // ── Historial médico ──────────────────────────────────────────────────────

  /// Guarda un registro en historial_medico.
  Future<HistorialModel> guardarHistorial(HistorialModel historial) async {
    final response = await _client
        .from('historial_medico')
        .insert(historial.toInsertJson())
        .select()
        .single();
    return HistorialModel.fromJson(response);
  }

  /// Obtiene el historial médico de una mascota.
  Future<List<HistorialModel>> obtenerHistorialMascota(
      String mascotaId) async {
    try {
      final response = await _client
          .from('historial_medico')
          .select()
          .eq('masc_id', mascotaId)
          .order('hist_fecha_consulta', ascending: false);
      return (response as List)
          .map((e) => HistorialModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo historial: $e');
      return [];
    }
  }
}
