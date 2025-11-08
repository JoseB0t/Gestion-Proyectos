import 'package:flutter/material.dart';
import 'package:neurodrive/data/repositories/auth_repository.dart';
import 'package:neurodrive/data/models/user_model.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isUser => _user?.isUser ?? false;

  /// Iniciar sesión
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final loggedUser = await _repository.loginUser(email, password);
      _user = loggedUser;

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registrar usuario
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String plate,
    required String emergencyContact,
    String role = 'user',
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newUser = await _repository.registerUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        plate: plate,
        emergencyContact: emergencyContact,
        role: role,
      );

      _user = newUser;

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }
}
