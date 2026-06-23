import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cita_model.dart';

class CitaService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String _selectConJoin = '''
    *,
    mascotas(masc_nombre),
    usuarios(usua_nombre)
  ''';

  /// Citas del día actual — filtra por fecha dentro del timestamp
  Future<List<CitaModel>> obtenerCitasHoy() async {
    try {
      final hoy = DateTime.now();
      final inicio = DateTime(hoy.year, hoy.month, hoy.day);
      final fin = inicio.add(const Duration(days: 1));
      final response = await _client
          .from('citas')
          .select(_selectConJoin)
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
          .select(_selectConJoin)
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
          .select(_selectConJoin)
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
          .select(_selectConJoin)
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
    // 1. Insertar la cita
    final inserted = await _client
        .from('citas')
        .insert(cita.toInsertJson())
        .select()
        .single();

    // 2. Volver a leer con join para obtener masc_nombre y propietario_nombre
    final citaId = inserted['cita_id']?.toString() ?? '';
    try {
      final full = await _client
          .from('citas')
          .select('''
            *,
            mascotas(masc_nombre),
            usuarios(usua_nombre)
          ''')
          .eq('cita_id', citaId)
          .single();
      return CitaModel.fromJson(full);
    } catch (_) {
      // Si el join falla, devolvemos lo que tenemos con los datos locales
      return CitaModel(
        id: citaId,
        usuarioId: cita.usuarioId,
        veteId: cita.veteId,
        mascotaId: cita.mascotaId,
        mascotaNombre: cita.mascotaNombre,
        propietarioNombre: cita.propietarioNombre,
        motivo: cita.motivo,
        fecha: cita.fecha,
        hora: cita.hora,
        estado: inserted['cita_estado'] as String? ?? cita.estado,
        direccion: cita.direccion,
      );
    }
  }

  /// Guarda descripción, receta y estado de una cita (uso del veterinario)
  /// y registra en historial_medico con diagnóstico y tratamiento.
  Future<CitaModel> guardarConsulta({
    required String citaId,
    required String estado,
    String? descripcion,
    String? receta,
    String? mascotaId,
    String? veteId,
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

    // Guardar en historial_medico si hay contenido clínico
    if ((descripcion != null && descripcion.isNotEmpty) ||
        (receta != null && receta.isNotEmpty)) {
      try {
        await _client.from('historial_medico').insert({
          if (mascotaId != null && mascotaId.isNotEmpty) 'masc_id': mascotaId,
          if (veteId != null && veteId.isNotEmpty) 'vete_id': veteId,
          if (descripcion != null && descripcion.isNotEmpty)
            'hist_diagnostico': descripcion,
          if (receta != null && receta.isNotEmpty)
            'hist_tratamiento': receta,
          'hist_fecha_consulta': DateTime.now()
              .toIso8601String()
              .split('T')
              .first,
        });
      } catch (e) {
        debugPrint('Error guardando historial: $e');
      }
    }

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
