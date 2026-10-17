import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/authorization/authorization_service.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  List<UserModel> _savedAccounts = [];
  bool _isLoading = false;
  bool _isAutoChecking = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get savedAccounts => List.unmodifiable(_savedAccounts);
  bool get isAuthenticated => _currentUser != null && _currentUser!.isActive;
  bool get isLoading => _isLoading;
  bool get isAutoChecking => _isAutoChecking;
  String? get errorMessage => _errorMessage;

  String get roleDisplayName => _currentUser?.roleDisplayName ?? (_currentUser?.roleName ?? 'Utilisateur');

  /// Check if user previously ticked "Remember Me" and restore session on app launch
  Future<bool> checkAutoLogin() async {
    _isAutoChecking = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isRemembered = prefs.getBool('is_remembered') ?? false;
      final savedUserId = prefs.getInt('saved_user_id');

      await _loadSavedAccounts(prefs);

      if (isRemembered && savedUserId != null) {
        final user = await DatabaseHelper.instance.getUserById(savedUserId);
        if (user != null && user.isActive) {
          _currentUser = user;
          AuthorizationService.instance.setCurrentUser(user);
          _isAutoChecking = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Auto login check error: $e');
    }

    _isAutoChecking = false;
    AuthorizationService.instance.setCurrentUser(null);
    notifyListeners();
    return false;
  }

  Future<void> _loadSavedAccounts(SharedPreferences prefs) async {
    final List<String> savedIds = prefs.getStringList('saved_account_ids') ?? [];
    final List<UserModel> loaded = [];

    for (final idStr in savedIds) {
      final id = int.tryParse(idStr);
      if (id != null) {
        final u = await DatabaseHelper.instance.getUserById(id);
        if (u != null && u.isActive) {
          loaded.add(u);
        }
      }
    }
    _savedAccounts = loaded;
  }

  Future<void> _persistSavedAccountId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedIds = prefs.getStringList('saved_account_ids') ?? [];
      final idStr = userId.toString();
      if (!savedIds.contains(idStr)) {
        savedIds.add(idStr);
        await prefs.setStringList('saved_account_ids', savedIds);
      }
      await _loadSavedAccounts(prefs);
    } catch (e) {
      debugPrint('Error persisting saved account: $e');
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await DatabaseHelper.instance.login(email, password);
      if (user != null) {
        _currentUser = user;
        AuthorizationService.instance.setCurrentUser(user);

        // Persist session
        final prefs = await SharedPreferences.getInstance();
        if (rememberMe) {
          await prefs.setBool('is_remembered', true);
          if (user.id != null) {
            await prefs.setInt('saved_user_id', user.id!);
            await _persistSavedAccountId(user.id!);
          }
          await prefs.setString('saved_email', email);
        } else {
          await prefs.setBool('is_remembered', false);
          await prefs.remove('saved_user_id');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Identifiants incorrects ou compte désactivé';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Secure account switch with password verification
  Future<bool> switchAccountWithPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await DatabaseHelper.instance.login(email, password);
      if (user != null) {
        final previousUser = _currentUser;
        _currentUser = user;
        AuthorizationService.instance.setCurrentUser(user);

        // Update active saved user ID in storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_remembered', true);
        if (user.id != null) {
          await prefs.setInt('saved_user_id', user.id!);
          await _persistSavedAccountId(user.id!);
        }

        // Audit log the password-verified account switch
        await DatabaseHelper.instance.logAudit(
          userId: user.id,
          userFullName: user.fullName,
          action: 'auth.switch_account',
          resource: 'Users',
          resourceId: user.id?.toString(),
          status: 'SUCCESS',
          reason: 'Changement de compte validé par mot de passe vers ${user.fullName} (depuis ${previousUser?.fullName ?? "Session"})',
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Mot de passe incorrect ou compte désactivé';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du changement de compte: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Authenticate and add a new account to saved list and switch to it immediately
  Future<bool> addAndSwitchAccount(String email, String password) async {
    return await switchAccountWithPassword(email, password);
  }

  /// Remove an account from saved accounts list
  Future<void> removeSavedAccount(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedIds = prefs.getStringList('saved_account_ids') ?? [];
      savedIds.remove(userId.toString());
      await prefs.setStringList('saved_account_ids', savedIds);
      await _loadSavedAccounts(prefs);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing saved account: $e');
    }
  }

  /// Reload active user details and permissions from local database
  Future<void> refreshCurrentUser() async {
    if (_currentUser?.id != null) {
      final freshUser = await DatabaseHelper.instance.getUserById(_currentUser!.id!);
      if (freshUser != null) {
        _currentUser = freshUser;
        AuthorizationService.instance.setCurrentUser(freshUser);
        final prefs = await SharedPreferences.getInstance();
        await _loadSavedAccounts(prefs);
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      await DatabaseHelper.instance.logAudit(
        userId: _currentUser!.id,
        userFullName: _currentUser!.fullName,
        action: 'auth.logout',
        resource: 'Users',
        resourceId: _currentUser!.id?.toString(),
        status: 'SUCCESS',
        reason: 'Déconnexion manuelle de l\'utilisateur',
      );
    }

    _currentUser = null;
    AuthorizationService.instance.setCurrentUser(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_remembered', false);
      await prefs.remove('saved_user_id');
    } catch (_) {}
    notifyListeners();
  }
}
