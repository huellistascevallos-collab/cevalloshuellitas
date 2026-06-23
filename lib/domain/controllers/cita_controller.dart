import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // ─── Notificaciones in-app de Citas ───────────────────────────────────────
  final List<CitaModel> _notificacionesCitas = [];
  dynamic _realtimeChannel; // RealtimeChannel

  List<CitaModel> get notificacionesCitas => List.unmodifiable(_notificacionesCitas);
  int get totalNotificaciones => _notificacionesCitas.length;

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
      // Extraer el mensaje limpio si es una Exception estándar
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();
      _errorMessage = msg;
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
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();
      _errorMessage = msg;
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
      final msg = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : e.toString();
      _errorMessage = msg;
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

  /// Suscribe al canal Realtime para recibir notificaciones de citas.
  /// - Si es veterinario: escucha INSERTS en la tabla 'citas' donde vete_id == entityId.
  /// - Si es usuario: escucha UPDATES en la tabla 'citas' donde usua_id == entityId.
  void suscribirNotificaciones({required String entityId, required String rol}) {
    _realtimeChannel?.unsubscribe();
    
    _realtimeChannel = Supabase.instance.client
        .channel('citas_realtime_$entityId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'citas',
          callback: (payload) async {
            final eventType = payload.eventType;
            final record = payload.newRecord;
            
            if (rol == 'veterinario') {
              if (eventType == PostgresChangeEvent.insert) {
                final veteId = record['vete_id']?.toString() ?? '';
                if (veteId == entityId) {
                  try {
                    final full = await Supabase.instance.client
                        .from('citas')
                        .select('''
                          *,
                          mascotas(masc_nombre),
                          usuarios(usua_nombre)
                        ''')
                        .eq('cita_id', record['cita_id'].toString())
                        .single();
                    
                    final model = CitaModel.fromJson(full);
                    _notificacionesCitas.insert(0, model);
                    
                    if (!_citasDelVeterinario.any((c) => c.id == model.id)) {
                      _citasDelVeterinario.insert(0, model);
                    }
                    notifyListeners();
                  } catch (e) {
                    debugPrint('Error obteniendo cita realtime: $e');
                  }
                }
              }
            } else if (rol == 'usuario') {
              if (eventType == PostgresChangeEvent.update) {
                final usuaId = record['usua_id']?.toString() ?? '';
                if (usuaId == entityId) {
                  final nuevoEstado = record['cita_estado']?.toString() ?? '';
                  final oldRecord = payload.oldRecord;
                  final antiguoEstado = oldRecord != null ? oldRecord['cita_estado']?.toString() : null;
                  
                  if (nuevoEstado != antiguoEstado && (nuevoEstado == 'confirmada' || nuevoEstado == 'rechazada')) {
                    try {
                      final full = await Supabase.instance.client
                          .from('citas')
                          .select('''
                            *,
                            mascotas(masc_nombre),
                            usuarios(usua_nombre)
                          ''')
                          .eq('cita_id', record['cita_id'].toString())
                          .single();
                      
                      final model = CitaModel.fromJson(full);
                      _notificacionesCitas.insert(0, model);
                      _actualizarEnListas(model);
                      notifyListeners();
                    } catch (e) {
                      debugPrint('Error obteniendo cita realtime: $e');
                    }
                  }
                }
              }
            }
          },
        )
        .subscribe();
  }

  void desuscribirNotificaciones() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  void marcarNotificacionVista(String id) {
    _notificacionesCitas.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void limpiarNotificaciones() {
    _notificacionesCitas.clear();
    notifyListeners();
  }
}
