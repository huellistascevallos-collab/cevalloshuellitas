import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';
import '../../supabase_config.dart';

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

    // Si se registra como veterinario, crear perfil en tabla veterinarios
    if (rol == 'veterinario') {
      await _crearPerfilVeterinarioSiNoExiste(userId);
    }

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

  /// Inicia sesión con Google usando el ID Token de Google y Supabase.
  ///
  /// Retorna el [UsuarioModel] del usuario autenticado.
  /// Si es la primera vez que el usuario inicia con Google, crea su perfil
  /// automáticamente en la tabla `usuarios`.
  Future<UsuarioModel> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      // serverClientId es el Web Client ID de Google Cloud Console.
      // En Android NO se usa clientId (ese es solo para iOS).
      // Este ID permite obtener el idToken necesario para Supabase.
      serverClientId: googleWebClientId,
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Inicio de sesión con Google cancelado.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('No se pudo obtener el token de Google.');
    }

    // Autenticar en Supabase con el ID Token de Google
    final authResponse = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );

    if (authResponse.user == null) {
      throw Exception('No se pudo autenticar con Google en Supabase.');
    }

    final userId = authResponse.user!.id;

    // Verificar si el perfil ya existe en la tabla usuarios
    final existing = await _client
        .from('usuarios')
        .select()
        .eq('usua_id', userId)
        .maybeSingle();

    if (existing == null) {
      // Primera vez con Google: crear perfil en la tabla usuarios
      final nombre = googleUser.displayName ?? googleUser.email.split('@').first;
      final correo = googleUser.email;

      await _client.from('usuarios').insert({
        'usua_id': userId,
        'usua_nombre': nombre,
        'usua_correo': correo,
        'usua_telefono': null,
        'usua_rol': 'usuario',
      });

      return UsuarioModel(
        id: userId,
        nombre: nombre,
        correo: correo,
        telefono: null,
        rol: 'usuario',
      );
    }

    return UsuarioModel.fromJson(existing);
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

  /// Actualiza el rol del usuario en la tabla `usuarios`.
  Future<void> updateUserProfile(String userId, String nombre, String telefono) async {
    await _client.from('usuarios').update({
      'usua_nombre': nombre,
      'usua_telefono': telefono,
    }).eq('usua_id', userId);
  }

  /// Actualiza el rol del usuario en la tabla `usuarios`.
  Future<void> updateUserRol(String userId, String nuevoRol) async {
    await _client.from('usuarios').update({
      'usua_rol': nuevoRol,
    }).eq('usua_id', userId);

    // Si el nuevo rol es veterinario, crear registro en tabla veterinarios
    // solo si no existe ya uno
    if (nuevoRol == 'veterinario') {
      await _crearPerfilVeterinarioSiNoExiste(userId);
    }
  }

  /// Crea un registro básico en la tabla `veterinarios` si no existe ya.
  Future<void> _crearPerfilVeterinarioSiNoExiste(String userId) async {
    try {
      final existing = await _client
          .from('veterinarios')
          .select('vete_id')
          .eq('usua_id', userId)
          .maybeSingle();
      if (existing == null) {
        await _client.from('veterinarios').insert({
          'usua_id': userId,
          'vete_disponible': true,
        });
      }
    } catch (e) {
      debugPrint('Error al crear perfil veterinario: $e');
    }
  }

  /// Retorna el usuario autenticado actualmente, o null si no hay sesión.
  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Verifica si hay una sesión activa.
  bool get isAuthenticated => _client.auth.currentSession != null;
}
