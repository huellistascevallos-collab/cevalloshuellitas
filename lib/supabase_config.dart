import 'package:supabase_flutter/supabase_flutter.dart';

/// URL del proyecto en Supabase
const String supabaseUrl = 'https://sjdlannkcqdupfoxxbxt.supabase.co';

/// Clave pública (anon key) de Supabase
const String supabaseAnonKey = 'sb_publishable_BIk1beMqBJnTrqqsKW1jng_lixaeoEz';

/// Acceso rápido al cliente de Supabase desde cualquier parte de la app.
///
/// Ejemplo de uso:
/// ```dart
/// final data = await supabase.from('mascotas').select();
/// ```
final supabase = Supabase.instance.client;
