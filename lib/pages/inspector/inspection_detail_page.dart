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
                  if (item.previousCertificateUrl != null || item.manufacturerCertificateUrl != null) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.slate100),
                    const SizedBox(height: 16),
                    const Text(
                      'ATTACHED DOCUMENTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.previousCertificateUrl != null)
                          Expanded(
                            child: _DocumentPreview(
                              title: 'Previous Certificate',
                              url: item.previousCertificateUrl!,
                            ),
                          ),
                        if (item.previousCertificateUrl != null && item.manufacturerCertificateUrl != null)
                          const SizedBox(width: 16),
                        if (item.manufacturerCertificateUrl != null)
                          Expanded(
                            child: _DocumentPreview(
                              title: 'Manufacturer Cert',
                              url: item.manufacturerCertificateUrl!,
                            ),
                          ),
                      ],
                    ),
                  ],
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

class _DocumentPreview extends StatelessWidget {
  final String title;
  final String url;

  const _DocumentPreview({required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    InteractiveViewer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(20),
                              child: const Text('Failed to load image'),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image_outlined, color: AppColors.slate),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}