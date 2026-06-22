import 'package:supabase_flutter/supabase_flutter.dart';

/// URL del proyecto en Supabase
const String supabaseUrl = 'https://sjdlannkcqdupfoxxbxt.supabase.co';

/// Clave pública (anon key) de Supabase
const String supabaseAnonKey = 'sb_publishable_BIk1beMqBJnTrqqsKW1jng_lixaeoEz';

/// Web Client ID de Google OAuth 2.0
/// Obténlo desde: https://console.cloud.google.com → Credenciales → OAuth 2.0
/// Debe ser el ID de tipo "Aplicación web" que Supabase genera automáticamente.
const String googleWebClientId =
    'TU_WEB_CLIENT_ID.apps.googleusercontent.com';

/// Acceso rápido al cliente de Supabase desde cualquier parte de la app.
///
/// Ejemplo de uso:
/// ```dart
/// final data = await supabase.from('mascotas').select();
/// ```
final supabase = Supabase.instance.client;
