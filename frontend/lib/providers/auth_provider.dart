import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  UserModel? _currentUser;
  String _currentRole = 'CUSTOMER';
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required this.apiService});

  UserModel? get currentUser => _currentUser;
  UserProfileModel? get profile => _currentUser?.profile;
  String get currentRole => _currentRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAdmin => _currentRole == 'ADMIN';
  bool get isReceptionist => _currentRole == 'RECEPTIONIST';
  bool get isMechanic => _currentRole == 'MECHANIC';
  bool get isCustomer => _currentRole == 'CUSTOMER';

  bool get isAuthenticated => _currentUser != null;

  Future<void> switchRole(String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await apiService.demoLogin(role);
      _currentUser = result['user'];
      _currentRole = role.toUpperCase();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await apiService.login(usernameOrEmail, password);
      _currentUser = result['user'];
      _currentRole = (_currentUser?.role ?? 'CUSTOMER').toUpperCase();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithFirebase(String idToken, {String role = 'CUSTOMER'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await apiService.firebaseLogin(idToken: idToken, role: role);
      _currentUser = result['user'];
      _currentRole = (_currentUser?.role ?? role).toUpperCase();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    String? avatarUrl,
    String? licensePlate,
    String? make,
    String? model,
    int? year,
    String? color,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await apiService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        licensePlate: licensePlate,
        make: make,
        model: model,
        year: year,
        color: color,
      );
      _currentUser = result['user'];
      _currentRole = (_currentUser?.role ?? 'CUSTOMER').toUpperCase();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    try {
      final updatedUser = await apiService.fetchCurrentUser();
      _currentUser = updatedUser;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await apiService.updateProfile(data);
      _currentUser = updatedUser;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    apiService.authToken = null;
    notifyListeners();
  }
}
