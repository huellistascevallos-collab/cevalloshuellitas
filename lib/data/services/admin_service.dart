import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';
import '../models/veterinario_model.dart';
import '../models/cita_model.dart';
import '../models/mascota_model.dart';
import '../models/solicitud_adopcion_model.dart';
import '../models/solicitud_rol_model.dart';
import 'solicitud_rol_service.dart';

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
  /// Si el nuevo rol es 'veterinario', crea el perfil en la tabla
  /// `veterinarios` si aún no existe (disponible=false para que el admin
  /// lo active manualmente). Si el rol cambia a cualquier otro, solo
  /// actualiza el campo de rol.
  Future<void> cambiarRolUsuario(String usuaId, String nuevoRol) async {
    if (nuevoRol == 'veterinario') {
      // Verificar si ya existe un perfil veterinario para este usuario
      final existente = await _client
          .from('veterinarios')
          .select('vete_id')
          .eq('usua_id', usuaId)
          .maybeSingle();

      if (existente == null) {
        // Crear perfil mínimo — disponible en false hasta que el admin lo active
        await _client.from('veterinarios').insert({
          'usua_id': usuaId,
          'vete_disponible': false,
        });
      }
    }
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
      final solicitudesRol = await _client
          .from('solicitudes_rol')
          .select('srol_id')
          .eq('srol_estado', 'pendiente');

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
        'solicitudes_rol': (solicitudesRol as List).length,
      };
    } catch (e) {
      debugPrint('AdminService.obtenerEstadisticas: $e');
      return {
        'usuarios': 0,
        'veterinarios': 0,
        'mascotas': 0,
        'citas': 0,
        'adopciones': 0,
        'solicitudes_rol': 0,
      };
    }
  }

  // ── Citas ─────────────────────────────────────────────────────────────────

  /// Todas las citas con join de mascotas, usuarios y veterinarios (para el admin).
  Future<List<CitaModel>> obtenerTodasLasCitas() async {
    try {
      final rows = await _client
          .from('citas')
          .select('*, mascotas(masc_nombre), usuarios(usua_nombre), veterinarios(usuarios(usua_nombre))')
          .order('cita_fecha', ascending: false);
      return (rows as List).map((e) => CitaModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('AdminService.obtenerTodasLasCitas: $e');
      return [];
    }
  }

  /// Elimina una cita por su ID.
  Future<void> eliminarCita(String citaId) async {
    await _client.from('citas').delete().eq('cita_id', citaId);
  }

  // ── Mascotas ──────────────────────────────────────────────────────────────

  /// Todas las mascotas con datos del propietario.
  Future<List<MascotaModel>> obtenerTodasLasMascotas() async {
    try {
      final rows = await _client
          .from('mascotas')
          .select('*, usuarios(usua_nombre, usua_telefono, usua_foto_url)')
          .order('masc_nombre');
      return (rows as List).map((e) => MascotaModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('AdminService.obtenerTodasLasMascotas: $e');
      return [];
    }
  }

  /// Elimina una mascota por su ID.
  Future<void> eliminarMascota(String mascotaId) async {
    await _client.from('mascotas').delete().eq('masc_id', mascotaId);
  }

  // ── Solicitudes de adopción ───────────────────────────────────────────────

  /// Todas las solicitudes de adopción con datos de mascota y solicitante.
  Future<List<SolicitudAdopcionModel>> obtenerTodasLasAdopciones() async {
    try {
      const join = '''
        *,
        mascotas(masc_nombre, masc_especie, masc_raza, masc_foto_url, usua_id),
        usuarios(usua_nombre, usua_correo, usua_telefono, usua_foto_url)
      ''';
      final rows = await _client
          .from('solicitudes_adopcion')
          .select(join)
          .order('soli_fecha', ascending: false);
      return (rows as List)
          .map((e) => SolicitudAdopcionModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('AdminService.obtenerTodasLasAdopciones: $e');
      return [];
    }
  }

  /// Elimina una solicitud de adopción.
  Future<void> eliminarAdopcion(String soliId) async {
    await _client.from('solicitudes_adopcion').delete().eq('soli_id', soliId);
  }

  // ── Solicitudes de rol ────────────────────────────────────────────────────

  final SolicitudRolService _solicitudRolService = SolicitudRolService();

  Future<List<SolicitudRolModel>> obtenerSolicitudesRol() =>
      _solicitudRolService.obtenerTodas();

  Future<List<SolicitudRolModel>> obtenerSolicitudesRolPendientes() =>
      _solicitudRolService.obtenerPendientes();

  Future<void> aprobarSolicitudRol(SolicitudRolModel solicitud) =>
      _solicitudRolService.aprobar(solicitud);

  Future<void> rechazarSolicitudRol(String srolId) =>
      _solicitudRolService.rechazar(srolId);

  Future<void> eliminarSolicitudRol(String srolId) =>
      _solicitudRolService.eliminar(srolId);
}
