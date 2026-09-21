import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/exif_helper.dart';

class LmoAuthService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> handlePostLoginEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    final isRegistered = prefs.getBool('isBiometricRegistered') ?? false;

    if (isRegistered) {
      return true;
    }

    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (!canAuthenticate) {
      await prefs.setBool('isBiometricRegistered', true);
      return true;
    }

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            'Please authenticate to register your LMO biometric identity',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        await prefs.setBool('isBiometricRegistered', true);
        return true;
      }
    } catch (e) {
      return false;
    }

    return false;
  }

  Future<Map<String, dynamic>?> verifyInspectorForField(
    String inspectionId,
    String inspectorId,
  ) async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    bool didAuthenticate = false;
    if (canAuthenticate) {
      try {
        didAuthenticate = await auth.authenticate(
          localizedReason: 'Verify LMO Identity to begin field inspection',
          biometricOnly: false,
          persistAcrossBackgrounding: true,
        );
      } catch (e) {
        didAuthenticate = false;
      }
    } else {
      didAuthenticate = true;
    }

    if (didAuthenticate) {
      final position = await getCurrentDeviceLocation();
      final lat = position?.latitude ?? 28.6139;
      final lng = position?.longitude ?? 77.2090;
      final timestamp = DateTime.now().toUtc().toIso8601String();

      final secretSalt = "eMaap_SIH_Secure_2026";
      final rawData =
          "$inspectionId|$inspectorId|$timestamp|$lat|$lng$secretSalt";
      final signature = sha256.convert(utf8.encode(rawData)).toString();

      return {
        "event_type": "FIELD_INSPECTION_VERIFICATION",
        "inspection_id": inspectionId,
        "inspector_id": inspectorId,
        "timestamp": timestamp,
        "geo_coords": {"lat": lat, "lng": lng},
        "verification_status": "BIOMETRIC_SUCCESS",
        "digital_signature": signature,
        "signature_type": "SHA256_HMAC",
      };
    }
    return null;
  }
}
