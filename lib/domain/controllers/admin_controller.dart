import 'package:flutter/material.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/veterinario_model.dart';
import '../../data/services/admin_service.dart';

class AdminController extends ChangeNotifier {
  final AdminService _service = AdminService();

  // ── Estado ────────────────────────────────────────────────────────────────
  List<UsuarioModel> _usuarios = [];
  List<VeterinarioModel> _veterinarios = [];
  Map<String, int> _estadisticas = {};
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<UsuarioModel> get usuarios => List.unmodifiable(_usuarios);
  List<VeterinarioModel> get veterinarios => List.unmodifiable(_veterinarios);
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

  Future<void> _cargarEstadisticas() async {
    try {
      _estadisticas = await _service.obtenerEstadisticas();
    } catch (e) {
      _errorMessage = 'Error al cargar estadísticas: $e';
    }
  }

  // ── Acciones sobre usuarios ───────────────────────────────────────────────

  Future<bool> cambiarRolUsuario(String usuaId, String nuevoRol) async {
    try {
      await _service.cambiarRolUsuario(usuaId, nuevoRol);
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
        notifyListeners();
      }
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
      // Actualizar el rol en la lista de usuarios también
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
}
