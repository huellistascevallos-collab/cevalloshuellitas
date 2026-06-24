import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Servicio singleton para notificaciones locales del sistema.
/// Gestiona notificaciones push (fuera de la app) y feedback in-app
/// (vibración + sonido) mediante flutter_local_notifications.
class NotificacionLocalService {
  NotificacionLocalService._();
  static final NotificacionLocalService instance = NotificacionLocalService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Canales Android ────────────────────────────────────────────────────────
  // Canal de alta prioridad: recordatorios a la hora exacta y citas rechazadas
  static const _channelUrgente    = 'huellitas_urgente';
  static const _channelUrgenteNom = 'Alertas Urgentes';
  static const _channelUrgenteDesc= 'Recordatorios inmediatos y alertas críticas';

  // Canal normal: solicitudes nuevas, confirmaciones, recordatorio 30 min
  static const _channelNormal    = 'huellitas_citas';
  static const _channelNormalNom = 'Citas y Recordatorios';
  static const _channelNormalDesc= 'Notificaciones de citas y adopciones';

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    // Inicializar zonas horarias
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Guayaquil'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      // Canal urgente — MAX importance, vibración larga
      await androidImpl.createNotificationChannel(
        AndroidNotificationChannel(
          _channelUrgente,
          _channelUrgenteNom,
          description: _channelUrgenteDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300, 200, 600]),
          enableLights: true,
          ledColor: const Color(0xFFE53935),
        ),
      );

      // Canal normal — HIGH importance, vibración corta
      await androidImpl.createNotificationChannel(
        AndroidNotificationChannel(
          _channelNormal,
          _channelNormalNom,
          description: _channelNormalDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
          enableLights: true,
          ledColor: const Color(0xFF1CB5C9),
        ),
      );

      // Solicitar permisos Android 13+
      await androidImpl.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('NotificacionLocalService inicializado.');
  }

  // ── Detalles por canal ─────────────────────────────────────────────────────
  NotificationDetails _detallesUrgente({String? subtext}) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelUrgente,
          _channelUrgenteNom,
          channelDescription: _channelUrgenteDesc,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300, 200, 600]),
          enableLights: true,
          ledColor: const Color(0xFFE53935),
          ledOnMs: 1000,
          ledOffMs: 500,
          subText: subtext,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  NotificationDetails _detallesNormal({String? subtext}) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelNormal,
          _channelNormalNom,
          channelDescription: _channelNormalDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
          enableLights: true,
          ledColor: const Color(0xFF1CB5C9),
          ledOnMs: 500,
          ledOffMs: 1000,
          subText: subtext,
          category: AndroidNotificationCategory.message,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      );

  // ── API pública ────────────────────────────────────────────────────────────

  /// Muestra notificación inmediata del sistema.
  /// [urgente] = true para recordatorio a la hora exacta o cita rechazada.
  Future<void> mostrarInmediata({
    required int id,
    required String titulo,
    required String cuerpo,
    bool urgente = false,
    String? subtext,
  }) async {
    if (!_initialized) await init();
    try {
      final detalles = urgente
          ? _detallesUrgente(subtext: subtext)
          : _detallesNormal(subtext: subtext);
      await _plugin.show(id, titulo, cuerpo, detalles);
    } catch (e) {
      debugPrint('Error al mostrar notificación: $e');
    }
  }

  /// Programa notificación en fecha/hora futura.
  /// [urgente] = true para el recordatorio a la hora exacta.
  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
    bool urgente = false,
    String? subtext,
  }) async {
    if (!_initialized) await init();
    if (fechaHora.isBefore(DateTime.now())) return;

    try {
      final tzFechaHora = tz.TZDateTime.from(fechaHora, tz.local);
      final detalles = urgente
          ? _detallesUrgente(subtext: subtext)
          : _detallesNormal(subtext: subtext);
      await _plugin.zonedSchedule(
        id,
        titulo,
        cuerpo,
        tzFechaHora,
        detalles,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
      debugPrint('Notificación programada id=$id para $fechaHora (urgente=$urgente)');
    } catch (e) {
      debugPrint('Error al programar notificación: $e');
    }
  }

  /// Vibración + feedback háptico in-app cuando la app está abierta.
  /// Llama esto al agregar una notificación mientras el usuario usa la app.
  Future<void> feedbackInApp({bool urgente = false}) async {
    try {
      if (urgente) {
        // Vibración pesada para recordatorio a la hora / cita rechazada
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        await HapticFeedback.heavyImpact();
      } else {
        // Vibración media para solicitudes y confirmaciones
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // El haptic puede no estar disponible en todos los dispositivos
    }
  }

  /// Cancela notificación programada por id.
  Future<void> cancelar(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancela todas las notificaciones.
  Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }

  /// Genera un id numérico único reproducible desde un string.
  static int idDesde(String texto) => texto.hashCode.abs() % 2147483647;
}
