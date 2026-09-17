import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../routes.dart';

class GeneratedCertificatePage extends StatelessWidget {
  final String inspectionId;
  const GeneratedCertificatePage({super.key, required this.inspectionId});

  @override
  Widget build(BuildContext context) {
    final item = inspectionFor(inspectionId);
    return Shell(
      role: AppRole.inspector,
      title: 'Certificate generated',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.green100, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 33),
            ),
            const SizedBox(height: 20),
            const Text('Certificate generated', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
              'Certificate sent to ${item.applicant} for ${item.business}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.slate, height: 1.5),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                children: [
                  Container(
                    height: 112,
                    width: 112,
                    decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
                    child: const QRPattern(),
                  ),
                  const SizedBox(height: 12),
                  const Text('LM/DL/2026/00453', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.inspectorHome, (r) => false),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
