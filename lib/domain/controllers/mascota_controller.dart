import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/mascota_model.dart';
import '../../data/services/mascota_service.dart';

class MascotaController extends ChangeNotifier {
  final MascotaService _mascotaService = MascotaService();

  List<MascotaModel> _mascotas = [];
  List<MascotaModel> _mascotasAdopcion = [];
  List<MascotaModel> _todasLasMascotas = [];
  final Set<String> _favoritos = {}; // IDs de mascotas favoritas
  bool _isLoading = false;
  bool _isLoadingAdopciones = false;
  String? _errorMessage;

  List<MascotaModel> get mascotas => _mascotas;
  List<MascotaModel> get mascotasAdopcion => _mascotasAdopcion;
  List<MascotaModel> get todasLasMascotas => _todasLasMascotas;
  Set<String> get favoritos => _favoritos;
  List<MascotaModel> get mascotasFavoritas =>
      _mascotasAdopcion.where((m) => _favoritos.contains(m.id)).toList();
  bool get isLoading => _isLoading;
  bool get isLoadingAdopciones => _isLoadingAdopciones;
  String? get errorMessage => _errorMessage;

  bool esFavorito(String id) => _favoritos.contains(id);

  void toggleFavorito(String id) {
    if (_favoritos.contains(id)) {
      _favoritos.remove(id);
    } else {
      _favoritos.add(id);
    }
    notifyListeners();
  }

  /// Carga las mascotas de un usuario específico.
  Future<void> cargarMascotas(String usuarioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _mascotas = await _mascotaService.obtenerMascotasPorUsuario(usuarioId);
    } catch (e) {
      _errorMessage = 'Error al cargar las mascotas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga todas las mascotas en estado de adopción.
  Future<void> cargarMascotasAdopcion() async {
    _isLoadingAdopciones = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _mascotasAdopcion = await _mascotaService.obtenerMascotasParaAdopcion();
    } catch (e) {
      _errorMessage = 'Error al cargar adopciones: $e';
    } finally {
      _isLoadingAdopciones = false;
      notifyListeners();
    }
  }

  /// Agrega una nueva mascota y la añade a la lista actual si es exitoso.
  Future<bool> agregarMascota(MascotaModel mascota) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nuevaMascota = await _mascotaService.crearMascota(mascota);
      _mascotas.add(nuevaMascota);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar la mascota: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualiza una mascota existente
  Future<bool> actualizarMascota(MascotaModel mascota) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final mascotaActualizada = await _mascotaService.actualizarMascota(mascota);
      
      // Actualizar en la lista local de mis mascotas
      final index = _mascotas.indexWhere((m) => m.id == mascota.id);
      if (index != -1) {
        _mascotas[index] = mascotaActualizada;
      }

      // Actualizar en la lista local de adopciones si corresponde
      final indexAdopcion = _mascotasAdopcion.indexWhere((m) => m.id == mascota.id);
      if (mascotaActualizada.estado.toLowerCase() == 'para adoptar') {
        if (indexAdopcion != -1) {
          _mascotasAdopcion[indexAdopcion] = mascotaActualizada;
        } else {
          _mascotasAdopcion.add(mascotaActualizada);
        }
      } else {
        if (indexAdopcion != -1) {
          _mascotasAdopcion.removeAt(indexAdopcion);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar la mascota: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sube una imagen de mascota delegando al servicio
  Future<String?> subirImagenMascota(File imagen, String extension) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = await _mascotaService.subirImagenMascota(imagen, extension);
      return url;
    } catch (e) {
      _errorMessage = 'Error al subir imagen: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia la lista de mascotas (útil al cerrar sesión)
  void limpiarMascotas() {
    _mascotas = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Carga TODAS las mascotas (para uso del veterinario).
  Future<void> cargarTodasLasMascotas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _todasLasMascotas = await _mascotaService.obtenerTodasLasMascotas();
    } catch (e) {
      _errorMessage = 'Error al cargar pacientes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
