import 'package:flutter/material.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/veterinario_model.dart';
import '../../data/models/cita_model.dart';
import '../../data/models/mascota_model.dart';
import '../../data/models/solicitud_adopcion_model.dart';
import '../../data/models/solicitud_rol_model.dart';
import '../../data/services/admin_service.dart';

class AdminController extends ChangeNotifier {
  final AdminService _service = AdminService();

  // ── Estado ────────────────────────────────────────────────────────────────
  List<UsuarioModel> _usuarios = [];
  List<VeterinarioModel> _veterinarios = [];
  List<CitaModel> _citas = [];
  List<MascotaModel> _mascotas = [];
  List<SolicitudAdopcionModel> _adopciones = [];
  List<SolicitudRolModel> _solicitudesRol = [];
  Map<String, int> _estadisticas = {};
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<UsuarioModel> get usuarios => List.unmodifiable(_usuarios);
  List<VeterinarioModel> get veterinarios => List.unmodifiable(_veterinarios);
  List<CitaModel> get citas => List.unmodifiable(_citas);
  List<MascotaModel> get mascotas => List.unmodifiable(_mascotas);
  List<SolicitudAdopcionModel> get adopciones => List.unmodifiable(_adopciones);
  List<SolicitudRolModel> get solicitudesRol => List.unmodifiable(_solicitudesRol);
  int get solicitudesRolPendientes =>
      _solicitudesRol.where((s) => s.estado == 'pendiente').length;
  Map<String, int> get estadisticas => _estadisticas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Carga inicial ─────────────────────────────────────────────────────────

  Future<void> cargarTodo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait([
        _cargarUsuarios(),
        _cargarVeterinarios(),
        _cargarEstadisticas(),
        _cargarSolicitudesRol(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarUsuarios() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _cargarUsuarios();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> cargarVeterinarios() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _cargarVeterinarios();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> cargarCitas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _cargarCitas();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> cargarMascotas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _cargarMascotas();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> cargarAdopciones() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _cargarAdopciones();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> cargarSolicitudesRol() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _cargarSolicitudesRol();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _cargarUsuarios() async {
    try {
      _usuarios = await _service.obtenerTodosLosUsuarios();
    } catch (e) {
      _errorMessage = 'Error al cargar usuarios: $e';
    }
  }

  Future<void> _cargarVeterinarios() async {
    try {
      _veterinarios = await _service.obtenerTodosLosVeterinarios();
    } catch (e) {
      _errorMessage = 'Error al cargar veterinarios: $e';
    }
  }

  Future<void> _cargarCitas() async {
    try {
      _citas = await _service.obtenerTodasLasCitas();
    } catch (e) {
      _errorMessage = 'Error al cargar citas: $e';
    }
  }

  Future<void> _cargarMascotas() async {
    try {
      _mascotas = await _service.obtenerTodasLasMascotas();
    } catch (e) {
      _errorMessage = 'Error al cargar mascotas: $e';
    }
  }

  Future<void> _cargarAdopciones() async {
    try {
      _adopciones = await _service.obtenerTodasLasAdopciones();
    } catch (e) {
      _errorMessage = 'Error al cargar adopciones: $e';
    }
  }

  Future<void> _cargarEstadisticas() async {
    try {
      _estadisticas = await _service.obtenerEstadisticas();
    } catch (e) {
      _errorMessage = 'Error al cargar estadísticas: $e';
    }
  }

  Future<void> _cargarSolicitudesRol() async {
    try {
      _solicitudesRol = await _service.obtenerSolicitudesRol();
    } catch (e) {
      _errorMessage = 'Error al cargar solicitudes de rol: $e';
    }
  }

  // ── Acciones sobre usuarios ───────────────────────────────────────────────

  Future<bool> cambiarRolUsuario(String usuaId, String nuevoRol) async {
    try {
      await _service.cambiarRolUsuario(usuaId, nuevoRol);
      // Actualizar rol en la lista local de usuarios
      final idx = _usuarios.indexWhere((u) => u.id == usuaId);
      if (idx != -1) {
        _usuarios[idx] = UsuarioModel(
          id: _usuarios[idx].id,
          nombre: _usuarios[idx].nombre,
          correo: _usuarios[idx].correo,
          telefono: _usuarios[idx].telefono,
          rol: nuevoRol,
          fechaRegistro: _usuarios[idx].fechaRegistro,
          fotoUrl: _usuarios[idx].fotoUrl,
        );
      }
      // Si se promovió a veterinario, recargar la lista de veterinarios
      if (nuevoRol == 'veterinario') {
        await _cargarVeterinarios();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar rol: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarUsuario(String usuaId) async {
    try {
      await _service.eliminarUsuario(usuaId);
      _usuarios.removeWhere((u) => u.id == usuaId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar usuario: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Acciones sobre veterinarios ───────────────────────────────────────────

  Future<bool> toggleDisponibilidad(String veteId, bool disponible) async {
    try {
      await _service.toggleDisponibilidadVeterinario(veteId, disponible);
      final idx = _veterinarios.indexWhere((v) => v.id == veteId);
      if (idx != -1) {
        _veterinarios[idx] = _veterinarios[idx].copyWith(disponible: disponible);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar disponibilidad: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarVeterinario(String veteId, String usuaId) async {
    try {
      await _service.eliminarVeterinario(veteId, usuaId);
      _veterinarios.removeWhere((v) => v.id == veteId);
      final idx = _usuarios.indexWhere((u) => u.id == usuaId);
      if (idx != -1) {
        _usuarios[idx] = UsuarioModel(
          id: _usuarios[idx].id,
          nombre: _usuarios[idx].nombre,
          correo: _usuarios[idx].correo,
          telefono: _usuarios[idx].telefono,
          rol: 'usuario',
          fechaRegistro: _usuarios[idx].fechaRegistro,
          fotoUrl: _usuarios[idx].fotoUrl,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar veterinario: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Acciones sobre citas ──────────────────────────────────────────────────

  Future<bool> eliminarCita(String citaId) async {
    try {
      await _service.eliminarCita(citaId);
      _citas.removeWhere((c) => c.id == citaId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar cita: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Acciones sobre mascotas ───────────────────────────────────────────────

  Future<bool> eliminarMascota(String mascotaId) async {
    try {
      await _service.eliminarMascota(mascotaId);
      _mascotas.removeWhere((m) => m.id == mascotaId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar mascota: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Acciones sobre adopciones ─────────────────────────────────────────────

  Future<bool> eliminarAdopcion(String soliId) async {
    try {
      await _service.eliminarAdopcion(soliId);
      _adopciones.removeWhere((a) => a.id == soliId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar solicitud de adopción: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Acciones sobre solicitudes de rol ─────────────────────────────────────

  Future<bool> aprobarSolicitudRol(SolicitudRolModel solicitud) async {
    try {
      await _service.aprobarSolicitudRol(solicitud);
      // Actualizar estado local
      final idx = _solicitudesRol.indexWhere((s) => s.id == solicitud.id);
      if (idx != -1) {
        _solicitudesRol[idx] = SolicitudRolModel(
          id: solicitud.id,
          usuaId: solicitud.usuaId,
          fecha: solicitud.fecha,
          estado: 'aprobada',
          usuarioNombre: solicitud.usuarioNombre,
          usuarioCorreo: solicitud.usuarioCorreo,
          usuarioFotoUrl: solicitud.usuarioFotoUrl,
          usuarioTelefono: solicitud.usuarioTelefono,
        );
      }
      // Actualizar rol en lista local de usuarios
      final uIdx = _usuarios.indexWhere((u) => u.id == solicitud.usuaId);
      if (uIdx != -1) {
        _usuarios[uIdx] = UsuarioModel(
          id: _usuarios[uIdx].id,
          nombre: _usuarios[uIdx].nombre,
          correo: _usuarios[uIdx].correo,
          telefono: _usuarios[uIdx].telefono,
          rol: 'veterinario',
          fechaRegistro: _usuarios[uIdx].fechaRegistro,
          fotoUrl: _usuarios[uIdx].fotoUrl,
        );
      }
      // Recargar lista de veterinarios para que aparezca el nuevo
      await _cargarVeterinarios();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al aprobar solicitud: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rechazarSolicitudRol(String srolId) async {
    try {
      await _service.rechazarSolicitudRol(srolId);
      final idx = _solicitudesRol.indexWhere((s) => s.id == srolId);
      if (idx != -1) {
        final s = _solicitudesRol[idx];
        _solicitudesRol[idx] = SolicitudRolModel(
          id: s.id,
          usuaId: s.usuaId,
          fecha: s.fecha,
          estado: 'rechazada',
          usuarioNombre: s.usuarioNombre,
          usuarioCorreo: s.usuarioCorreo,
          usuarioFotoUrl: s.usuarioFotoUrl,
          usuarioTelefono: s.usuarioTelefono,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al rechazar solicitud: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarSolicitudRol(String srolId) async {
    try {
      await _service.eliminarSolicitudRol(srolId);
      _solicitudesRol.removeWhere((s) => s.id == srolId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar solicitud: $e';
      notifyListeners();
      return false;
    }
  }
}
