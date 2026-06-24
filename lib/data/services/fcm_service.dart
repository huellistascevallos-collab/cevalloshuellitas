import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notificacion_local_service.dart';

/// Handler de mensajes en segundo plano (debe ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
  // flutter_local_notifications ya muestra la notificación del sistema
  // automáticamente cuando la app está en background gracias al canal
  // configurado en NotificacionLocalService.
}

/// Servicio que gestiona Firebase Cloud Messaging.
/// - Solicita permisos al usuario
/// - Obtiene y guarda el token FCM en Supabase (tabla usuarios)
/// - Escucha mensajes en primer plano y los convierte en notificaciones locales
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Inicializa FCM: permisos, token, y listeners.
  /// Llama esto una vez en main() después de inicializar Firebase.
  Future<void> init() async {
    // Verificar que Firebase esté disponible antes de usar FCM
    try {
      Firebase.app(); // lanza FirebaseException si no hay app inicializada
    } on FirebaseException catch (e) {
      debugPrint('FcmService.init() abortado — Firebase no disponible: $e');
      return;
    }
    // 1. Registrar handler de background (antes de cualquier otra cosa)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Solicitar permisos en iOS (Android 13+ se pide en NotificacionLocalService)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 3. Configurar presentación en primer plano (iOS)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Escuchar mensajes cuando la app está en PRIMER PLANO
    FirebaseMessaging.onMessage.listen(_onMensajePrimerPlano);

    // 5. Escuchar cuando el usuario toca la notificación desde background
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificacionAbierta);

    debugPrint('FcmService inicializado.');
  }

  /// Obtiene el token FCM actual y lo guarda en Supabase para el usuario [userId].
  Future<void> guardarToken(String userId) async {
    try {
      Firebase.app(); // guard: abortar si Firebase no está inicializado
    } on FirebaseException {
      debugPrint('guardarToken abortado — Firebase no disponible.');
      return;
    }
    try {
      // En Android el token puede tardar un momento
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM: token nulo, reintentando...');
        return;
      }
      debugPrint('FCM token: $token');

      // Guardar en la columna fcm_token de la tabla usuarios
      await Supabase.instance.client
          .from('usuarios')
          .update({'fcm_token': token})
          .eq('usua_id', userId);

      debugPrint('FCM token guardado en Supabase para $userId');

      // Escuchar renovación de token y actualizarlo en Supabase
      _fcm.onTokenRefresh.listen((nuevoToken) async {
        await Supabase.instance.client
            .from('usuarios')
            .update({'fcm_token': nuevoToken})
            .eq('usua_id', userId);
        debugPrint('FCM token renovado para $userId');
      });
    } catch (e) {
      debugPrint('Error guardando token FCM: $e');
    }
  }

  /// Elimina el token FCM del usuario al cerrar sesión.
  Future<void> limpiarToken(String userId) async {
    try {
      Firebase.app(); // guard: abortar si Firebase no está inicializado
    } on FirebaseException {
      debugPrint('limpiarToken abortado — Firebase no disponible.');
      return;
    }
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'fcm_token': null})
          .eq('usua_id', userId);
      await _fcm.deleteToken();
      debugPrint('FCM token eliminado para $userId');
    } catch (e) {
      debugPrint('Error limpiando token FCM: $e');
    }
  }

  // ── Handlers de mensajes ──────────────────────────────────────────────────

  /// Cuando llega un mensaje con la app en PRIMER PLANO, lo mostramos
  /// como notificación local (FCM no la muestra automáticamente en foreground).
  Future<void> _onMensajePrimerPlano(RemoteMessage message) async {
    debugPrint('FCM foreground: ${message.notification?.title}');
    final notif = message.notification;
    if (notif == null) return;

    final esAdopcion = message.data['tipo'] == 'adopcion';

    await NotificacionLocalService.instance.mostrarInmediata(
      id: NotificacionLocalService.idDesde(message.messageId ?? notif.title ?? ''),
      titulo: notif.title ?? '🐾 Huellitas',
      cuerpo: notif.body ?? '',
      urgente: false,
      subtext: message.data['mascota'],
      payload: message.data['payload'],
    );

    // Vibración según tipo
    await NotificacionLocalService.instance.feedbackInApp(urgente: !esAdopcion);
  }

  /// Cuando el usuario toca la notificación desde background/terminado.
  void _onNotificacionAbierta(RemoteMessage message) {
    debugPrint('FCM notificación abierta: ${message.data}');
    // La navegación se maneja desde el onTap del NotificacionLocalService
    // que ya está configurado en main.dart
  }
}
