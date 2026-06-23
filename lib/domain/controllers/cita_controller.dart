import 'package:flutter/material.dart';
import '../../data/models/cita_model.dart';
import '../../data/services/cita_service.dart';

class CitaController extends ChangeNotifier {
  final CitaService _citaService = CitaService();

  List<CitaModel> _citasHoy = [];
  List<CitaModel> _todasLasCitas = [];
  List<CitaModel> _citasDelUsuario = [];
  List<CitaModel> _citasDelVeterinario = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CitaModel> get citasHoy => _citasHoy;
  List<CitaModel> get todasLasCitas => _todasLasCitas;
  List<CitaModel> get citasDelUsuario => _citasDelUsuario;
  List<CitaModel> get citasDelVeterinario => _citasDelVeterinario;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get citasPendientesHoy =>
      _citasHoy.where((c) => c.estado == 'pendiente' || c.estado == 'confirmada').length;
  int get citasCompletadasHoy =>
      _citasHoy.where((c) => c.estado == 'completada').length;

  Future<void> cargarCitasHoy() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _citasHoy = await _citaService.obtenerCitasHoy();
    } catch (e) {
      _errorMessage = 'Error al cargar citas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarTodasLasCitas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _todasLasCitas = await _citaService.obtenerTodasLasCitas();
    } catch (e) {
      _errorMessage = 'Error al cargar historial: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarCitasDeUsuario(String usuarioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _citasDelUsuario = await _citaService.obtenerCitasPorUsuario(usuarioId);
    } catch (e) {
      _errorMessage = 'Error al cargar historial: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarCitasDeVeterinario(String veteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _citasDelVeterinario = await _citaService.obtenerCitasPorVeterinario(veteId);
    } catch (e) {
      _errorMessage = 'Error al cargar historial: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> crearCita(CitaModel cita) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final nueva = await _citaService.crearCita(cita);
      _citasHoy.add(nueva);
      _citasDelUsuario.insert(0, nueva);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al crear cita: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarEstado(String citaId, String nuevoEstado) async {
    try {
      final actualizada = await _citaService.actualizarEstadoCita(citaId, nuevoEstado);
      _actualizarEnListas(actualizada);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar estado: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> guardarConsulta({
    required String citaId,
    required String estado,
    String? descripcion,
    String? receta,
    String? mascotaId,
    String? veteId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final actualizada = await _citaService.guardarConsulta(
        citaId: citaId,
        estado: estado,
        descripcion: descripcion,
        receta: receta,
        mascotaId: mascotaId,
        veteId: veteId,
      );
      _actualizarEnListas(actualizada);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar consulta: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _actualizarEnListas(CitaModel actualizada) {
    final id = actualizada.id;
    final idx0 = _citasHoy.indexWhere((c) => c.id == id);
    if (idx0 != -1) _citasHoy[idx0] = actualizada;
    final idx1 = _todasLasCitas.indexWhere((c) => c.id == id);
    if (idx1 != -1) _todasLasCitas[idx1] = actualizada;
    final idx2 = _citasDelVeterinario.indexWhere((c) => c.id == id);
    if (idx2 != -1) _citasDelVeterinario[idx2] = actualizada;
    final idx3 = _citasDelUsuario.indexWhere((c) => c.id == id);
    if (idx3 != -1) _citasDelUsuario[idx3] = actualizada;
  }
}
