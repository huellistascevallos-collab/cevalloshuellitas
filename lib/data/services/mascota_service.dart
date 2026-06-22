import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mascota_model.dart';

class MascotaService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todas las mascotas registradas para un usuario específico.
  Future<List<MascotaModel>> obtenerMascotasPorUsuario(String usuarioId) async {
    final response = await _client
        .from('mascotas')
        .select()
        .eq('usua_id', usuarioId);

    return (response as List<dynamic>)
        .map((e) => MascotaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene todas las mascotas (para el veterinario).
  Future<List<MascotaModel>> obtenerTodasLasMascotas() async {
    final response = await _client.from('mascotas').select().order('masc_nombre');
    return (response as List<dynamic>)
        .map((e) => MascotaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene todas las mascotas que están en estado "para adoptar" en la plataforma.
  Future<List<MascotaModel>> obtenerMascotasParaAdopcion() async {
    final response = await _client
        .from('mascotas')
        .select()
        .eq('masc_estado', 'para adoptar');

    return (response as List<dynamic>)
        .map((e) => MascotaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crea una nueva mascota en la base de datos y retorna el modelo con su ID asignado.
  Future<MascotaModel> crearMascota(MascotaModel mascota) async {
    final response = await _client
        .from('mascotas')
        .insert(mascota.toInsertJson())
        .select()
        .single();
    return MascotaModel.fromJson(response);
  }

  /// Actualiza los datos de una mascota existente.
  Future<MascotaModel> actualizarMascota(MascotaModel mascota) async {
    final response = await _client
        .from('mascotas')
        .update(mascota.toUpdateJson())
        .eq('masc_id', mascota.id)
        .select()
        .single();
    return MascotaModel.fromJson(response);
  }

  /// Sube una imagen a Supabase Storage y retorna la URL pública.
  Future<String?> subirImagenMascota(File imagen, String extension) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final ruta = 'mascotas/$fileName';
      
      await _client.storage.from('mascotas_imagenes').upload(
            ruta,
            imagen,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl =
          _client.storage.from('mascotas_imagenes').getPublicUrl(ruta);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return null;
    }
  }
}
