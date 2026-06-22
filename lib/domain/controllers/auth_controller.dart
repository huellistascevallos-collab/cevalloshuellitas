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
        _errorMessage = null; // El usuario canceló, no es un error
      } else {
        _errorMessage = 'Error al iniciar sesión con Google.';
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
