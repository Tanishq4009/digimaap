import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/lmo_auth_service.dart';
import '../services/socket_service.dart';

class LmoAuthProvider extends ChangeNotifier {
  final LmoAuthService _authService = LmoAuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _userId;
  String? _token;
  bool _fingerprintRegistered = false;

  bool get isAuthenticated => _token != null;
  bool get fingerprintRegistered => _fingerprintRegistered;
  String? get userId => _userId;

  Future<void> initAutoLogin(
    BuildContext context,
    VoidCallback onSuccess,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('auth_userId');
    _fingerprintRegistered =
        prefs.getBool('fingerprintRegistered') ?? false;

    if (_token != null && _fingerprintRegistered) {
      final success = await _triggerLocalAuth(
        'Please authenticate to login seamlessly',
      );
      if (success) {
        SocketService().joinOfficerRoom(_userId!);
        onSuccess();
      }
    }
  }

  Future<bool> login(
    String employeeId,
    String password,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _authService.login(
        employeeId,
        password,
      );

      _token = data['token'];
      _userId = data['userId'];
      _fingerprintRegistered =
          data['fingerprintRegistered'] ?? false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_userId', _userId!);
      await prefs.setBool(
        'fingerprintRegistered',
        _fingerprintRegistered,
      );

      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerBiometrics() async {
    _setLoading(true);
    _error = null;

    final success = await _triggerLocalAuth(
      'Please authenticate to register your LMO biometric identity',
    );

    if (success) {
      try {
        await _authService.registerFingerprint(
          _userId!,
          _token!,
        );
        _fingerprintRegistered = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('fingerprintRegistered', true);

        _setLoading(false);
        return true;
      } on ApiException catch (e) {
        _error = e.message;
        _setLoading(false);
        return false;
      } catch (e) {
        _error =
            'Failed to sync biometric registration with server';
        _setLoading(false);
        return false;
      }
    } else {
      _error =
          'Biometric verification cancelled or failed locally';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> _triggerLocalAuth(String reason) async {
    final bool canCheck =
        await _authService.auth.canCheckBiometrics;
    final bool isDeviceSupported = await _authService.auth
        .isDeviceSupported();

    if (!canCheck && !isDeviceSupported) {
      // Device does not support biometrics, bypass for dev/simulator
      return true;
    }

    try {
      return await _authService.auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (e) {
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _fingerprintRegistered = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_userId');
    await prefs.remove('fingerprintRegistered');
    notifyListeners();
  }
}
