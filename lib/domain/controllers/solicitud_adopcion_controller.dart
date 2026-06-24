import 'package:flutter/material.dart';
import '../../data/models/solicitud_adopcion_model.dart';
import '../../data/services/solicitud_adopcion_service.dart';
import '../../data/services/notificacion_local_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SolicitudAdopcionController extends ChangeNotifier {
  final SolicitudAdopcionService _service = SolicitudAdopcionService();

  List<SolicitudAdopcionModel> _misSolicitudes = [];
  List<SolicitudAdopcionModel> _solicitudesRecibidas = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Notificaciones in-app ────────────────────────────────────────────────
  /// Solicitudes recibidas aún no vistas por el dueño.
  final List<SolicitudAdopcionModel> _notificacionesPendientes = [];
  RealtimeChannel? _realtimeChannel;

  List<SolicitudAdopcionModel> get misSolicitudes => _misSolicitudes;
  List<SolicitudAdopcionModel> get solicitudesRecibidas => _solicitudesRecibidas;
  List<SolicitudAdopcionModel> get notificacionesPendientes =>
      List.unmodifiable(_notificacionesPendientes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendientesRecibidas =>
      _solicitudesRecibidas.where((s) => s.estado == 'Pendiente').length;

  int get totalNotificaciones => _notificacionesPendientes.length;

  // ─── Realtime: escuchar nuevas solicitudes para las mascotas del dueño ───

  /// Suscribe al canal Realtime para recibir notificaciones cuando llegan
  /// nuevas solicitudes dirigidas a las mascotas del [duenioId].
  void suscribirNotificaciones(String duenioId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('solicitudes_duenio_$duenioId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'solicitudes_adopcion',
          callback: (payload) async {
            final nueva = payload.newRecord;
            final mascId = nueva['masc_id']?.toString() ?? '';

            // Verificar que la mascota pertenece al dueño actual
            try {
              final mascota = await Supabase.instance.client
                  .from('mascotas')
                  .select('usua_id, masc_nombre')
                  .eq('masc_id', mascId)
                  .single();

              if (mascota['usua_id']?.toString() != duenioId) return;

              // Obtener datos del solicitante
              final solicitudCompleta = await Supabase.instance.client
                  .from('solicitudes_adopcion')
                  .select(
                      '*, mascotas(masc_nombre, masc_especie, masc_raza, masc_foto_url, usua_id), usuarios(usua_nombre, usua_correo, usua_telefono, usua_foto_url)')
                  .eq('soli_id', nueva['soli_id'].toString())
                  .single();

              final model = SolicitudAdopcionModel.fromJson(solicitudCompleta);
              _notificacionesPendientes.insert(0, model);

              // También agregar a la lista de recibidas
              if (!_solicitudesRecibidas.any((s) => s.id == model.id)) {
                _solicitudesRecibidas.insert(0, model);
              }

              // ── Notificación push + feedback in-app ──────────────────────
              final mascNombre = model.mascotaNombre ?? 'tu mascota';
              final solicitanteNom = model.usuarioNombre ?? 'Alguien';
              final notifId = NotificacionLocalService.idDesde('adopcion_${model.id}');

              // Vibración in-app
              NotificacionLocalService.instance.feedbackInApp(urgente: false);

              // Push del sistema
              NotificacionLocalService.instance.mostrarInmediata(
                id: notifId,
                titulo: '🐾 Nueva solicitud de adopción',
                cuerpo: '$solicitanteNom quiere adoptar a $mascNombre.',
                urgente: false,
                subtext: mascNombre,
              );

              notifyListeners();
            } catch (e) {
              debugPrint('Error en notificación realtime: $e');
            }
          },
        )
        .subscribe();
  }

  void desuscribirNotificaciones() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  /// Marca una notificación como vista (la elimina del badge).
  void marcarNotificacionVista(String soliId) {
    _notificacionesPendientes.removeWhere((n) => n.id == soliId);
    notifyListeners();
  }

  /// Limpia todas las notificaciones pendientes.
  void limpiarNotificaciones() {
    _notificacionesPendientes.clear();
    notifyListeners();
  }

  // ─── Solicitudes ─────────────────────────────────────────────────────────

  /// Envía una solicitud de adopción.
  Future<bool> enviarSolicitud({
    required String usuaId,
    required String mascId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final nueva = await _service.enviarSolicitud(
          usuaId: usuaId, mascId: mascId);
      _misSolicitudes.insert(0, nueva);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Carga las solicitudes enviadas por el usuario logueado.
  Future<void> cargarMisSolicitudes(String usuaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _misSolicitudes = await _service.obtenerPorUsuario(usuaId);
    } catch (e) {
      _errorMessage = 'Error al cargar solicitudes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las solicitudes recibidas para las mascotas del dueño logueado.
  Future<void> cargarSolicitudesRecibidas(String duenioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _solicitudesRecibidas = await _service.obtenerPorDueno(duenioId);
    } catch (e) {
      _errorMessage = 'Error al cargar solicitudes recibidas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirma la adopción: cambia el dueño de la mascota al solicitante
  /// y actualiza el estado de la mascota a 'propio'.
  Future<bool> confirmarAdopcion(SolicitudAdopcionModel solicitud) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final actualizada = await _service.confirmarAdopcion(solicitud);
      _actualizarEnListas(actualizada);
      // Quitar de recibidas pendientes (la mascota ya no está en adopción)
      _solicitudesRecibidas.removeWhere(
        (s) => s.mascId == solicitud.mascId && s.id != solicitud.id,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al confirmar adopción: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Rechaza una solicitud (dueño de la mascota).
  Future<bool> rechazarSolicitud(String soliId) async {
    return _cambiarEstado(soliId, 'Rechazada');
  }

  /// Cancela una solicitud pendiente (el solicitante).
  Future<bool> cancelarSolicitud(String soliId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.cancelarSolicitud(soliId);
      _misSolicitudes.removeWhere((s) => s.id == soliId);
      _solicitudesRecibidas.removeWhere((s) => s.id == soliId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cancelar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verifica el estado actual de la solicitud de un usuario para una mascota.
  Future<String?> estadoSolicitud({
    required String usuaId,
    required String mascId,
  }) async {
    return _service.estadoSolicitud(usuaId: usuaId, mascId: mascId);
  }

  Future<bool> _cambiarEstado(String soliId, String nuevoEstado) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final actualizada = await _service.actualizarEstado(soliId, nuevoEstado);
      _actualizarEnListas(actualizada);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar estado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _actualizarEnListas(SolicitudAdopcionModel actualizada) {
    final i1 = _misSolicitudes.indexWhere((s) => s.id == actualizada.id);
    if (i1 != -1) _misSolicitudes[i1] = actualizada;
    final i2 = _solicitudesRecibidas.indexWhere((s) => s.id == actualizada.id);
    if (i2 != -1) _solicitudesRecibidas[i2] = actualizada;
  }

  void limpiar() {
    desuscribirNotificaciones();
    _misSolicitudes = [];
    _solicitudesRecibidas = [];
    _notificacionesPendientes.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
