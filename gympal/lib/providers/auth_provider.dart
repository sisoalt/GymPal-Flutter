import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/hive_service.dart';

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
        _currentUser = userBox.values.firstWhere(
          (user) => user.username == activeUsername,
        );

        // Sync user's weight and height to settings if available
        if (_currentUser?.weight != null) {
          await settingsBox.put('user_weight', _currentUser!.weight!);
        }
        if (_currentUser?.height != null) {
          await settingsBox.put('user_height', _currentUser!.height!);
        }
      } catch (e) {
        await logout();
      }
    }
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));

    final userBox = HiveService.userBox;
    final settingsBox = HiveService.settingsBox;

    try {
      final user = userBox.values.firstWhere(
        (u) => u.username == username && u.password == password,
      );

      _currentUser = user;
      await settingsBox.put('active_user_session', username);

      // Sync user's weight and height to settings if available
      if (user.weight != null) {
        await settingsBox.put('user_weight', user.weight!);
      }
      if (user.height != null) {
        await settingsBox.put('user_height', user.height!);
      }

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return "Invalid username or password";
    }
  }

  Future<String?> register(UserModel newUser) async {
    _setLoading(true);
    final userBox = HiveService.userBox;
    final settingsBox = HiveService.settingsBox;

    final exists = userBox.values.any((u) => u.username == newUser.username);

    if (exists) {
      _setLoading(false);
      return "Username already taken";
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

    _setLoading(false);
    return null;
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

      user.password = newPassword;
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

    if (_currentUser!.password != currentPassword) {
      _setLoading(false);
      return "Incorrect current password";
    }

    try {
      _currentUser!.password = newPassword;
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
}
