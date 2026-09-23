import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class LmoAuthService {
  final LocalAuthentication auth = LocalAuthentication();
  final String baseUrl = 'http://192.168.1.4:8008'; 

  Future<Map<String, dynamic>> login(String employeeId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login/lmo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'employeeId': employeeId, 'password': password}),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData['success'] == true) {
      return responseData['data'];
    } else {
      throw ApiException(responseData['error'] ?? 'Login failed', response.statusCode);
    }
  }

  Future<void> registerFingerprint(String userId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/lmo/$userId/register-fingerprint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      _handleError(response);
      throw ApiException('Failed to register fingerprint on server', response.statusCode);
    }
  }

  void _handleError(http.Response response) {
    if (response.statusCode == 400) {
      throw ApiException('Invalid employee ID or password', 400);
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized access', 401);
    } else if (response.statusCode == 403) {
      throw ApiException('Account blocked or forbidden', 403);
    } else {
      throw ApiException('Server error: ${response.statusCode}', response.statusCode);
    }
  }

  Future<bool> verifyInspectorForField(String inspectionId, String inspectorId) async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    bool didAuthenticate = false;
    if (canAuthenticate) {
      try {
        didAuthenticate = await auth.authenticate(
          localizedReason: 'Verify LMO Identity to begin field inspection',
          biometricOnly: true,
        );
      } catch (e) {
        didAuthenticate = false;
      }
    } else {
      didAuthenticate = true;
    }

    return didAuthenticate;
  }
}
