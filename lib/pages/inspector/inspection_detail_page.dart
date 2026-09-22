import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../services/lmo_auth_service.dart';
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
      final authService = LmoAuthService();
      final success = await authService.verifyInspectorForField(
        widget.inspectionId,
        "LMO_OFFICER_01",
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspector Verified Successfully.'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChecklistPage(
              inspectionId: widget.inspectionId,
            ),
          ),
        );
      } else {
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