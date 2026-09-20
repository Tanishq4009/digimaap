import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../routes.dart';

class BiometricEnrollmentScreen extends StatefulWidget {
  const BiometricEnrollmentScreen({super.key});

  @override
  State<BiometricEnrollmentScreen> createState() =>
      _BiometricEnrollmentScreenState();
}

class _BiometricEnrollmentScreenState extends State<BiometricEnrollmentScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<void> _enrollBiometrics() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // If device doesn't support biometrics, bypass for mock purposes or show error
        _onSuccess();
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            'Please authenticate to register your LMO biometric identity',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        _onSuccess();
      }
    } catch (e) {
      debugPrint('Error enrolling biometrics: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric enrollment failed. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _onSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricRegistered', true);

    if (mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Routes.inspectorHome, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shell(
      nav: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fingerprint_rounded,
                size: 100,
                color: AppColors.navy,
              ),
              const SizedBox(height: 32),
              const Text(
                'LMO Identity Verification',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'As per the anti-proxy guidelines, Legal Metrology Officers must register their biometrics on this device.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.slate,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _isAuthenticating
                  ? const CircularProgressIndicator(color: AppColors.saffron)
                  : PrimaryButton(
                      onPressed: _enrollBiometrics,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security),
                          SizedBox(width: 8),
                          Text('Register Biometrics'),
                        ],
                      ),
                    ),
              const SizedBox(height: 16),
              if (!_isAuthenticating)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel Login',
                    style: TextStyle(color: AppColors.slate),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
