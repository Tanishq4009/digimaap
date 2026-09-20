import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../utils/exif_helper.dart'; // for getCurrentDeviceLocation
import 'checklist_page.dart';

class InspectionDetailPage extends StatefulWidget {
  final String inspectionId;
  const InspectionDetailPage({super.key, required this.inspectionId});

  @override
  State<InspectionDetailPage> createState() => _InspectionDetailPageState();
}

class _InspectionDetailPageState extends State<InspectionDetailPage> {
  bool _isVerifying = false;

  Future<void> _verifyLMOAndBegin() async {
    setState(() => _isVerifying = true);
    try {
      final auth = LocalAuthentication();
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      bool didAuthenticate = false;
      if (canAuthenticate) {
        didAuthenticate = await auth.authenticate(
          localizedReason: 'Verify LMO Identity to begin field inspection',
          biometricOnly: false,
          persistAcrossBackgrounding: true,
        );
      } else {
        // Fallback if device doesn't support
        didAuthenticate = true;
      }

      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isInspectorVerified', true);

        // Fetch location for mock audit log
        final position = await getCurrentDeviceLocation();

        // Print mock socket payload
        final payload = {
          "inspection_id": widget.inspectionId,
          "inspector_id": "LMO_OFFICER_01",
          "timestamp": DateTime.now().toIso8601String(),
          "geo_coords": {
            "lat": position?.latitude ?? 28.6139,
            "lng": position?.longitude ?? 77.2090,
          },
          "verification_status": "BIOMETRIC_SUCCESS",
        };
        debugPrint('ANTI-PROXY VERIFICATION PAYLOAD: $payload');

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChecklistPage(inspectionId: widget.inspectionId),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspector Verification Failed. Access Denied.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('Biometric error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspector Verification Failed. Access Denied.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = inspectionFor(widget.inspectionId);
    return Shell(
      role: AppRole.inspector,
      title: 'Inspection pre-check',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.priority} ASSIGNMENT',
                    style: const TextStyle(
                      color: AppColors.saffron,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.business,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.address} · ${item.distance}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.slate100),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.6,
                    children: [
                      InfoGridItem(label: 'Applicant', value: item.applicant),
                      InfoGridItem(label: 'Instrument', value: item.instrument),
                      InfoGridItem(label: 'Make / model', value: item.model),
                      InfoGridItem(label: 'Serial number', value: item.serial),
                      InfoGridItem(
                        label: 'Scheduled',
                        value: '12 Jan 2026 · ${item.time}',
                      ),
                      const InfoGridItem(
                        label: 'Last certificate',
                        value: 'LM/DL/2025/00918',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _isVerifying
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.saffron),
                  )
                : PrimaryButton(
                    onPressed: _verifyLMOAndBegin,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, size: 18),
                        SizedBox(width: 8),
                        Text('Verify LMO & Begin'),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
