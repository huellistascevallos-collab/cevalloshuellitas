import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/servicio_model.dart';

class ServicioService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los servicios del catálogo.
  Future<List<ServicioModel>> obtenerServicios() async {
    try {
      final response = await _client
          .from('servicios')
          .select()
          .order('serv_nombre');
      return (response as List)
          .map((e) => ServicioModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener servicios: $e');
      return [];
    }
  }

  /// Obtiene los veterinarios que atienden un servicio específico,
  /// haciendo join con la tabla veterinarios para obtener su info.
  Future<List<VeterinarioServicioModel>> obtenerVeterinariosPorServicio(
      String servId) async {
    try {
      final response = await _client
          .from('veterinario_servicios')
          .select('*, veterinarios(vete_especialidad, vete_disponible, vete_experiencia, vete_tarifa, vete_foto_url, vete_latitud, vete_longitud, vete_direccion, usuarios(usua_nombre, usua_foto_url))')
          .eq('serv_id', servId);
      return (response as List)
          .map((e) => VeterinarioServicioModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener vets por servicio: $e');
      return [];
    }
  }

  /// Asigna un servicio a un veterinario.
  Future<void> asignarServicio({
    required String veteId,
    required String servId,
    double? precio,
    String? duracion,
  }) async {
    await _client.from('veterinario_servicios').insert({
      'vete_id': veteId,
      'serv_id': servId,
      'vese_precio': precio,
      'vese_duracion': duracion?.isNotEmpty == true ? duracion : null,
    });
  }

  /// Elimina la asignación de un servicio a un veterinario.
  Future<void> quitarServicio(String veseId) async {
    await _client
        .from('veterinario_servicios')
        .delete()
        .eq('vese_id', veseId);
  }

  /// Obtiene los servicios asignados a un veterinario específico.
  Future<List<VeterinarioServicioModel>> obtenerServiciosPorVeterinario(
      String veteId) async {
    try {
      final response = await _client
          .from('veterinario_servicios')
          .select('*, servicios(serv_nombre, serv_descripcion, serv_icono)')
          .eq('vete_id', veteId);
      return (response as List)
          .map((e) => VeterinarioServicioModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener servicios del vet: $e');
      return [];
    }
  }
}
