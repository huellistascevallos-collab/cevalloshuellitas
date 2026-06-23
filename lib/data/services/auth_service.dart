import 'dart:io';
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
      serverClientId: googleWebClientId,
      scopes: ['email', 'profile'],
    );

    // Forzar selección de cuenta siempre (evita tokens cacheados corruptos)
    await googleSignIn.signOut();

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.signIn();
    } catch (e) {
      throw Exception('Error al abrir Google: $e');
    }

    if (googleUser == null) {
      throw Exception('Inicio de sesión con Google cancelado.');
    }

    GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      throw Exception('Error obteniendo autenticación de Google: $e');
    }

    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception(
          'No se pudo obtener el token de Google. '
          'Verifica que el Web Client ID en supabase_config.dart '
          'sea el OAuth de tipo "Aplicación web".');
    }

    // Autenticar en Supabase
    AuthResponse authResponse;
    try {
      authResponse = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
    } catch (e) {
      throw Exception('Error autenticando en Supabase con Google: $e');
    }

    if (authResponse.user == null) {
      throw Exception('Supabase no devolvió un usuario tras el login con Google.');
    }

    final userId = authResponse.user!.id;
    final nombre =
        googleUser.displayName ?? googleUser.email.split('@').first;
    final correo = googleUser.email;

    // Verificar si el perfil ya existe
    Map<String, dynamic>? existing;
    try {
      existing = await _client
          .from('usuarios')
          .select()
          .eq('usua_id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error verificando perfil: $e');
      existing = null;
    }

    if (existing == null) {
      // Primera vez — crear perfil
      try {
        await _client.from('usuarios').insert({
          'usua_id': userId,
          'usua_nombre': nombre,
          'usua_correo': correo,
          'usua_telefono': null,
          'usua_rol': 'usuario',
        });
      } catch (e) {
        throw Exception(
            'No se pudo crear el perfil del usuario en la base de datos: $e. '
            'Verifica las políticas RLS de la tabla "usuarios" en Supabase.');
      }

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

  /// Envía un OTP de recuperación de contraseña al email indicado.
  Future<void> enviarRecuperacionContrasena(String correo) async {
    await _client.auth.resetPasswordForEmail(correo.trim());
  }

  /// Verifica el OTP de recuperación y actualiza la contraseña.
  /// Lanza excepción si el código es incorrecto o expiró.
  Future<void> verificarOtpYCambiarContrasena({
    required String correo,
    required String otp,
    required String nuevaContrasena,
  }) async {
    // 1. Verificar el OTP — esto crea una sesión temporal
    final response = await _client.auth.verifyOTP(
      email: correo.trim(),
      token: otp.trim(),
      type: OtpType.recovery,
    );

    if (response.user == null) {
      throw Exception('Código inválido o expirado. Solicita uno nuevo.');
    }

    // 2. Con la sesión activa, actualizar la contraseña
    await _client.auth.updateUser(
      UserAttributes(password: nuevaContrasena),
    );
  }

  /// Sube la foto de perfil del usuario a Supabase Storage
  /// y actualiza el campo `usua_foto_url` en la tabla `usuarios`.
  /// Lanza excepción si algo falla.
  Future<String> subirFotoUsuario(String userId, File imagen, String extension) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ruta = 'perfiles/$fileName';

    await _client.storage.from('usuarios_imagenes').upload(
          ruta,
          imagen,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    final String publicUrl =
        _client.storage.from('usuarios_imagenes').getPublicUrl(ruta);

    // Guardar la URL en la tabla usuarios
    await _client
        .from('usuarios')
        .update({'usua_foto_url': publicUrl})
        .eq('usua_id', userId);

    return publicUrl;
  }

  /// Retorna el usuario autenticado actualmente, o null si no hay sesión.
  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Verifica si hay una sesión activa.
  bool get isAuthenticated => _client.auth.currentSession != null;
}
