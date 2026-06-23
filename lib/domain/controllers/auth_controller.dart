import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/auth_service.dart';

/// Controlador de autenticación que maneja el estado de login/registro.
///
/// Usa [ChangeNotifier] para notificar a la UI de cambios de estado.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;
  UsuarioModel? _currentUser;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  UsuarioModel? get currentUser => _currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Intenta iniciar sesión con las credenciales proporcionadas.
  ///
  /// Retorna `true` si el login fue exitoso, `false` en caso contrario.
  Future<bool> login(String correo, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(
        correo: correo.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error en login: $e');
      _errorMessage = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Intenta iniciar sesión con Google.
  ///
  /// Retorna `true` si el login fue exitoso, `false` en caso contrario.
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelado')) {
        _errorMessage = null;
      } else {
        // Mostramos el mensaje completo para poder diagnosticar
        _errorMessage = msg
            .replaceAll('Exception: ', '')
            .replaceAll('exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registra un nuevo usuario con los datos proporcionados.
  ///
  /// Retorna `true` si el registro fue exitoso, `false` en caso contrario.
  Future<bool> register({
    required String nombre,
    required String correo,
    required String password,
    String? telefono,
    String rol = 'usuario',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signUp(
        nombre: nombre.trim(),
        correo: correo.trim(),
        password: password,
        telefono: telefono?.trim(),
        rol: rol,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error en registro: $e');
      _errorMessage = 'Error al crear la cuenta: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión actual y limpia el estado.
  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Intenta restaurar la sesión anterior al abrir la app.
  Future<void> tryRestoreSession() async {
    _isInitializing = true;
    notifyListeners();

    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      try {
        _currentUser = await _authService.getUserProfile(userId);
      } catch (e) {
        debugPrint('Error al restaurar sesión: $e');
      }
    }

    // Espera un pequeño tiempo mínimo para reproducir el GIF (1.2 segundos)
    await Future.delayed(const Duration(milliseconds: 1200));

    _isInitializing = false;
    notifyListeners();
  }

  /// Sube la foto de perfil del usuario y actualiza el estado local.
  Future<bool> subirFotoUsuario(File imagen, String extension) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await _authService.subirFotoUsuario(
        _currentUser!.id,
        imagen,
        extension,
      );
      _currentUser = UsuarioModel(
        id: _currentUser!.id,
        nombre: _currentUser!.nombre,
        correo: _currentUser!.correo,
        telefono: _currentUser!.telefono,
        rol: _currentUser!.rol,
        fechaRegistro: _currentUser!.fechaRegistro,
        fotoUrl: url,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al subir la foto: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el perfil del usuario actual (nombre y teléfono).
  Future<bool> updateProfile(String nombre, String telefono) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUserProfile(_currentUser!.id, nombre, telefono);
      _currentUser = UsuarioModel(
        id: _currentUser!.id,
        nombre: nombre,
        correo: _currentUser!.correo,
        telefono: telefono,
        rol: _currentUser!.rol,
        fechaRegistro: _currentUser!.fechaRegistro,
        fotoUrl: _currentUser!.fotoUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar el perfil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cambia el rol del usuario y actualiza el estado local.
  Future<bool> updateRol(String nuevoRol) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updateUserRol(_currentUser!.id, nuevoRol);
      _currentUser = UsuarioModel(
        id: _currentUser!.id,
        nombre: _currentUser!.nombre,
        correo: _currentUser!.correo,
        telefono: _currentUser!.telefono,
        rol: nuevoRol,
        fechaRegistro: _currentUser!.fechaRegistro,
        fotoUrl: _currentUser!.fotoUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar el rol: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Envía un OTP de recuperación de contraseña.
  Future<bool> recuperarContrasena(String correo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.enviarRecuperacionContrasena(correo.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo enviar el correo. Verifica la dirección.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verifica el código OTP y cambia la contraseña.
  Future<bool> verificarOtpYCambiarContrasena({
    required String correo,
    required String otp,
    required String nuevaContrasena,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.verificarOtpYCambiarContrasena(
        correo: correo,
        otp: otp,
        nuevaContrasena: nuevaContrasena,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cambia la contraseña del usuario autenticado.
  Future<bool> cambiarContrasena(String nuevaContrasena) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: nuevaContrasena),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al cambiar la contraseña.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mapea mensajes de error de Supabase Auth a mensajes en español.
  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('User already registered')) {
      return 'Este correo ya está registrado.';
    }
    if (message.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Debes confirmar tu correo electrónico.';
    }
    return 'Error de autenticación: $message';
  }
}
