import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/hive_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadSession() async {
    final settingsBox = HiveService.settingsBox;
    final activeUsername = settingsBox.get('active_user_session');

    if (activeUsername != null) {
      final userBox = HiveService.userBox;
      try {
        // Wait a small moment to ensure box is ready
        await Future.delayed(const Duration(milliseconds: 100));
        
        final safeActiveUsername = activeUsername.toString().trim().toLowerCase();
        _currentUser = userBox.values.firstWhere(
          (user) => user.username.trim().toLowerCase() == safeActiveUsername,
        );

        // Sync user's weight and height to settings if available
        if (_currentUser?.weight != null) {
          await settingsBox.put('user_weight', _currentUser!.weight!);
        }
        if (_currentUser?.height != null) {
          await settingsBox.put('user_height', _currentUser!.height!);
        }
      } catch (e) {
        // If user not found, clear the invalid session
        await logout();
      }
    }
    notifyListeners();
  }

  Future<String?> login(String username, String password, {bool remember = false}) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));

    final userBox = HiveService.userBox;
    final settingsBox = HiveService.settingsBox;

    final safeUsername = username.trim();
    final safePassword = password.trim();

    try {
      final safeUsernameLower = safeUsername.toLowerCase();
      final hashedPassword = _hashPassword(safePassword);
      
      final user = userBox.values.firstWhere(
        (u) => 
          u.username.trim().toLowerCase() == safeUsernameLower && 
          u.password == hashedPassword,
      );

      _currentUser = user;
      await settingsBox.put('active_user_session', user.username);

      // Credential persistence (Remember Me)
      if (remember) {
        await settingsBox.put('remembered_username', safeUsername);
        await settingsBox.put('remembered_password', safePassword);
        await settingsBox.put('remember_me', true);
      } else {
        await settingsBox.delete('remembered_username');
        await settingsBox.delete('remembered_password');
        await settingsBox.put('remember_me', false);
      }

      // Sync user's weight and height to settings if available
      if (user.weight != null) {
        await settingsBox.put('user_weight', user.weight!);
      }
      if (user.height != null) {
        await settingsBox.put('user_height', user.height!);
      }

      await settingsBox.flush();

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Invalid username or password";
    }
  }

  Map<String, dynamic> getRememberedCredentials() {
    final settingsBox = HiveService.settingsBox;
    return {
      'username': settingsBox.get('remembered_username') ?? '',
      'password': settingsBox.get('remembered_password') ?? '',
      'rememberMe': settingsBox.get('remember_me') ?? false,
    };
  }

  Future<String?> register(UserModel newUser) async {
    _setLoading(true);
    final userBox = HiveService.userBox;
    final settingsBox = HiveService.settingsBox;

    final safeUsername = newUser.username.trim();
    
    final exists = userBox.values.any(
      (u) => u.username.trim().toLowerCase() == safeUsername.toLowerCase()
    );

    if (exists) {
      _setLoading(false);
      return "Username already taken";
    }

    // Hash the password before storing
    newUser.password = _hashPassword(newUser.password.trim());
    if (newUser.securityAnswer != null) {
      newUser.securityAnswer = _hashPassword(newUser.securityAnswer!.trim().toLowerCase()); // Normalize answer
    }
    if (newUser.pin != null) {
      newUser.pin = _hashPassword(newUser.pin!.trim());
    }

    await userBox.add(newUser);
    _currentUser = newUser;
    await settingsBox.put('active_user_session', newUser.username);

    // Sync user's weight and height to settings if available
    if (newUser.weight != null) {
      await settingsBox.put('user_weight', newUser.weight!);
    }
    if (newUser.height != null) {
      await settingsBox.put('user_height', newUser.height!);
    }

    await userBox.flush();
    await settingsBox.flush();

    _setLoading(false);
    return null;
  }

  // Verification Methods
  UserModel? getUserByUsername(String username) {
    final userBox = HiveService.userBox;
    try {
      return userBox.values.firstWhere(
        (u) => u.username.trim().toLowerCase() == username.trim().toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  bool verifySecurityAnswer(String username, String answer) {
    final user = getUserByUsername(username);
    if (user == null || user.securityAnswer == null) return false;
    return user.securityAnswer == _hashPassword(answer.trim().toLowerCase());
  }

  bool verifyPin(String username, String pin) {
    final user = getUserByUsername(username);
    if (user == null || user.pin == null) return false;
    return user.pin == _hashPassword(pin.trim());
  }
  
  bool verifyAge(String username, int age) {
    final user = getUserByUsername(username);
    if (user == null) return false;
    return user.age == age;
  }

  // --- THIS IS THE MISSING METHOD ---
  Future<void> updateProfile(
    String fullName,
    int age,
    String gender, {
    double? height,
    double? weight,
  }) async {
    if (_currentUser != null) {
      _currentUser!.fullName = fullName;
      _currentUser!.age = age;
      _currentUser!.gender = gender;
      _currentUser!.height = height;
      _currentUser!.weight = weight;

      // Save changes to Hive persistence
      await _currentUser!.save();

      // Also save weight and height to settings for progress tracking
      final settingsBox = HiveService.settingsBox;
      if (height != null) {
        await settingsBox.put('user_height', height);
      }
      if (weight != null) {
        await settingsBox.put('user_weight', weight);
      }

      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String? imagePath) async {
    if (_currentUser != null) {
      _currentUser!.profileImagePath = imagePath;
      await _currentUser!.save();
      notifyListeners();
    }
  }

  Future<String?> resetPassword(String username, String newPassword) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));

    final userBox = HiveService.userBox;
    try {
      final user = userBox.values.firstWhere(
        (u) => u.username == username,
        orElse: () => throw Exception("User not found"),
      );

      user.password = _hashPassword(newPassword);
      await user.save();
      
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "User not found";
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
     _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser == null) {
      _setLoading(false);
      return "No active session";
    }

    if (_currentUser!.password != _hashPassword(currentPassword)) {
      _setLoading(false);
      return "Incorrect current password";
    }

    try {
      _currentUser!.password = _hashPassword(newPassword);
      await _currentUser!.save();
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Failed to update password";
    }
  }

  Future<void> logout() async {
    final settingsBox = HiveService.settingsBox;
    await settingsBox.delete('active_user_session');
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
