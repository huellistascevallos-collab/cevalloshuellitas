import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cita_model.dart';

class CitaService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Citas del día actual — filtra por fecha dentro del timestamp
  Future<List<CitaModel>> obtenerCitasHoy() async {
    try {
      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin = inicio.add(const Duration(days: 1));
      final response = await _client
          .from('citas')
          .select()
          .gte('cita_fecha', inicio.toIso8601String())
          .lt('cita_fecha', fin.toIso8601String())
          .order('cita_fecha');
      return (response as List).map((e) => CitaModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error citasHoy: $e');
      return [];
    }
  }

  /// Todas las citas ordenadas por fecha descendente
  Future<List<CitaModel>> obtenerTodasLasCitas() async {
    try {
      final response = await _client
          .from('citas')
          .select()
          .order('cita_fecha', ascending: false);
      return (response as List).map((e) => CitaModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error todasCitas: $e');
      return [];
    }
  }

  /// Citas de un usuario específico (dueño de mascotas)
  Future<List<CitaModel>> obtenerCitasPorUsuario(String usuarioId) async {
    try {
      final response = await _client
          .from('citas')
          .select()
          .eq('usua_id', usuarioId)
          .order('cita_fecha', ascending: false);
      return (response as List).map((e) => CitaModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error citasUsuario: $e');
      return [];
    }
  }

  /// Citas de un veterinario específico
  Future<List<CitaModel>> obtenerCitasPorVeterinario(String veteId) async {
    try {
      final response = await _client
          .from('citas')
          .select()
          .eq('vete_id', veteId)
          .order('cita_fecha', ascending: false);
      return (response as List).map((e) => CitaModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error citasVet: $e');
      return [];
    }
  }

  /// Crea una nueva cita usando toInsertJson()
  Future<CitaModel> crearCita(CitaModel cita) async {
    final response = await _client
        .from('citas')
        .insert(cita.toInsertJson())
        .select()
        .single();
    return CitaModel.fromJson(response);
  }

  /// Guarda descripción, receta y estado de una cita (uso del veterinario)
  Future<CitaModel> guardarConsulta({
    required String citaId,
    required String estado,
    String? descripcion,
    String? receta,
  }) async {
    final response = await _client
        .from('citas')
        .update({
          'cita_estado': estado,
          if (descripcion != null) 'cita_descripcion': descripcion,
          if (receta != null) 'cita_receta': receta,
        })
        .eq('cita_id', citaId)
        .select()
        .single();
    return CitaModel.fromJson(response);
  }

  /// Actualiza el estado de una cita
  Future<CitaModel> actualizarEstadoCita(
      String citaId, String nuevoEstado) async {
    final response = await _client
        .from('citas')
        .update({'cita_estado': nuevoEstado})
        .eq('cita_id', citaId)
        .select()
        .single();
    return CitaModel.fromJson(response);
  }
}
