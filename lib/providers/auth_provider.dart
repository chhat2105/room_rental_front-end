import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null && _api.token != null;
  bool get isLandlord => _user?.isLandlord ?? false;
  bool get isTenant => _user?.isTenant ?? true;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await _api.init();
    _user = await _api.getCachedUser();
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.login(username, password);
      _user = res.user;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
        role: role,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout(_user?.id);
    _user = null;
    notifyListeners();
  }
}
