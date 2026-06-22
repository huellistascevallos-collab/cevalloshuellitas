import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/veterinario_model.dart';

class VeterinarioService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los veterinarios registrados, con la foto de perfil
  /// del usuario asociado (usua_foto_url).
  Future<List<VeterinarioModel>> obtenerTodos() async {
    try {
      final response = await _client
          .from('veterinarios')
          .select('*, usuarios(usua_nombre, usua_foto_url)')
          .order('vete_id');
      return (response as List)
          .map((e) => VeterinarioModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener todos los veterinarios: $e');
      return [];
    }
  }

  /// Obtiene el perfil del veterinario por su usua_id.
  Future<VeterinarioModel?> obtenerPorUsuarioId(String usuarioId) async {
    try {
      final response = await _client
          .from('veterinarios')
          .select('*, usuarios(usua_nombre, usua_foto_url)')
          .eq('usua_id', usuarioId)
          .maybeSingle();
      if (response == null) return null;
      return VeterinarioModel.fromJson(response);
    } catch (e) {
      debugPrint('Error al obtener veterinario: $e');
      return null;
    }
  }

  /// Crea un nuevo registro en veterinarios.
  Future<VeterinarioModel> crearVeterinario(VeterinarioModel vet) async {
    debugPrint('Creando veterinario: ${vet.toInsertJson()}');
    final response = await _client
        .from('veterinarios')
        .insert(vet.toInsertJson())
        .select()
        .single();
    return VeterinarioModel.fromJson(response);
  }

  /// Actualiza el perfil de un veterinario existente por vete_id.
  Future<VeterinarioModel> actualizarVeterinario(VeterinarioModel vet) async {
    debugPrint('Actualizando vete_id=${vet.id}');
    final response = await _client
        .from('veterinarios')
        .update(vet.toUpdateJson())
        .eq('vete_id', vet.id)
        .select()
        .single();
    return VeterinarioModel.fromJson(response);
  }
}
