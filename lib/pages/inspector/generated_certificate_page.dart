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
              decoration: BoxDecoration(
                color: AppColors.green100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 33,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Certificate generated',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Certificate sent to ${item.applicant} for ${item.business}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate,
                height: 1.5,
              ),
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
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const QRPattern(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'LM/DL/2026/00453',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.navy.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.navy,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Anti-Proxy Audit Trail',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Inspector Status',
                    style: TextStyle(fontSize: 10, color: AppColors.slate),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Biometrically Verified On-Site',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Geo-Location Logged',
                    style: TextStyle(fontSize: 10, color: AppColors.slate),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '28.6139° N, 77.2090° E (Mock)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Timestamp',
                    style: TextStyle(fontSize: 10, color: AppColors.slate),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateTime.now().toString().split('.').first,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(Routes.inspectorHome, (r) => false),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
