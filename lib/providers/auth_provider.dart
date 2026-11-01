import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthController _controller;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = true;

  AuthProvider({required AuthController controller}) : _controller = controller {
    _currentUser = _controller.currentUser;
    _controller.authStateChanges.listen((user) {
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }, onError: (err) {
      debugPrint('authStateChanges error: $err');
    });
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;

  void toggleRememberMe(bool? val) {
    _rememberMe = val ?? false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _controller.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseAuthError(e);
      notifyListeners();
      return false;
    }
  }

  void loginWithDefaultAdmin() {
    _currentUser = AuthRepository.defaultAdminUser;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _controller.logout();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  String _parseAuthError(dynamic error) {
    final str = error.toString();
    if (str.contains('wrong-password') || str.contains('invalid-credential')) {
      return 'Invalid email address or password.';
    } else if (str.contains('user-not-found')) {
      return 'No account found with this email.';
    } else if (str.contains('invalid-email')) {
      return 'The email address is improperly formatted.';
    }
    return str.replaceAll('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
  }
}
