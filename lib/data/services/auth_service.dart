import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

/// Servicio de autenticación que conecta con Supabase Auth
/// y la tabla `usuarios` para gestionar perfiles.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Registra un nuevo usuario con Supabase Auth y crea su perfil
  /// en la tabla `usuarios`.
  ///
  /// Retorna el [UsuarioModel] creado o lanza una excepción.
  Future<UsuarioModel> signUp({
    required String nombre,
    required String correo,
    required String password,
    String? telefono,
    String rol = 'usuario',
  }) async {
    // 1. Registrar en Supabase Auth
    final authResponse = await _client.auth.signUp(
      email: correo,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('No se pudo crear la cuenta. Intenta de nuevo.');
    }

    final userId = authResponse.user!.id;

    // 2. Crear perfil en la tabla usuarios
    final userData = {
      'usua_id': userId,
      'usua_nombre': nombre,
      'usua_correo': correo,
      'usua_telefono': telefono,
      'usua_rol': rol,
    };

    await _client.from('usuarios').insert(userData);

    return UsuarioModel(
      id: userId,
      nombre: nombre,
      correo: correo,
      telefono: telefono,
      rol: rol,
    );
  }

  /// Inicia sesión con email y contraseña vía Supabase Auth.
  ///
  /// Retorna el [UsuarioModel] del usuario autenticado.
  Future<UsuarioModel> signIn({
    required String correo,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: correo,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Credenciales inválidas.');
    }

    // Obtener el perfil desde la tabla usuarios
    final profile = await getUserProfile(authResponse.user!.id);
    return profile;
  }

  /// Cierra la sesión actual del usuario.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Obtiene el perfil del usuario desde la tabla `usuarios`.
  Future<UsuarioModel> getUserProfile(String userId) async {
    final response = await _client
        .from('usuarios')
        .select()
        .eq('usua_id', userId)
        .single();

    return UsuarioModel.fromJson(response);
  }

  /// Retorna el usuario autenticado actualmente, o null si no hay sesión.
  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Verifica si hay una sesión activa.
  bool get isAuthenticated => _client.auth.currentSession != null;
}
