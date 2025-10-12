import 'package:flutter/material.dart';
import 'package:neurodrive/data/models/user_model.dart';

/// Simple auth manager storing a user in memory (replace later with repository)
class AuthProvider extends ChangeNotifier {
  static final AuthProvider instance = AuthProvider._private();
  AuthProvider._private();

  UserModel? _userModel;
  bool get isLogged => _userModel != null;
  UserModel? get user => _userModel;

  Future<bool> login(String email, String password) async {
    // Simulated login: accept any email/password for now
    await Future.delayed(const Duration(milliseconds: 700));
    _userModel = UserModel(id: 'u1', name: 'Conductor', email: email, phone: '3000000000', plate: 'ABC123', emergencyContact: '3001112222');
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _userModel = null;
    notifyListeners();
  }

  Future<bool> register(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 700));
    _userModel = UserModel(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? 'Sin nombre',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      plate: data['plate'] ?? '',
      emergencyContact: data['emergency'] ?? '',
    );
    notifyListeners();
    return true;
  }
}
