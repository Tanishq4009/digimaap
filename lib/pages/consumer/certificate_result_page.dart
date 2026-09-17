import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../routes.dart';

class CertificateResultPage extends StatelessWidget {
  final String certId;
  final bool forceExpired;
  final bool forceNotFound;

  const CertificateResultPage({
    super.key,
    required this.certId,
    this.forceExpired = false,
    this.forceNotFound = false,
  });

  @override
  Widget build(BuildContext context) {
    final item = certificates[certId];

    if (item == null || forceNotFound) {
      return Shell(
        role: AppRole.consumer,
        title: 'Certificate result',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.red200),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.red100, shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text('No record found', style: TextStyle(color: AppColors.errorRed, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('No record found for this certificate number.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.5)),
                    const SizedBox(height: 12),
                    const Text('This may indicate a counterfeit or tampered certificate.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.errorRed)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                onPressed: () => Navigator.of(context).pushNamed(Routes.consumerReport),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Report to Legal Metrology'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ]),
              ),
            ],
          ),
        ),
      );
    }

    final expired = forceExpired || item.status == 'expired';

    return Shell(
      role: AppRole.consumer,
      title: 'Certificate result',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: expired ? AppColors.red50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: expired ? Border.all(color: AppColors.red200) : null,
                boxShadow: expired
                    ? null
                    : const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: expired ? AppColors.red100 : AppColors.green50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          expired ? Icons.warning_amber_rounded : Icons.check_rounded,
                          color: expired ? AppColors.errorRed : AppColors.success,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expired ? 'CERTIFICATE EXPIRED' : 'VERIFIED CERTIFICATE',
                              style: TextStyle(
                                color: expired ? AppColors.errorRed : AppColors.success,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expired
                                  ? "This instrument's certification has lapsed."
                                  : 'Real-time record found · SHA-256 secured',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.slate200, height: 1),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.6,
                    children: [
                      InfoGridItem(label: 'Instrument type', value: item.instrument),
                      InfoGridItem(label: 'Category', value: item.category),
                      InfoGridItem(label: 'Certificate no.', value: item.number),
                      InfoGridItem(label: 'Issuing authority', value: item.authority),
                      InfoGridItem(label: 'Issue date', value: item.issueDate),
                      InfoGridItem(
                        label: 'Expiry date',
                        value: item.expiryDate,
                        valueColor: expired ? AppColors.errorRed : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (expired) ...[
              const SizedBox(height: 16),
              PrimaryButton(
                onPressed: () => Navigator.of(context).pushNamed(Routes.consumerReport),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Report to Legal Metrology'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Photo evidence verified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(999)),
                        child: const Text('SEALED', style: TextStyle(color: AppColors.navy, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(gradient: AppColors.sealTexture, borderRadius: BorderRadius.circular(12)),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        color: Colors.black.withValues(alpha: 0.6),
                        child: const Text('SEAL\nMP-452', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: AppColors.slate200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 16, color: AppColors.navy),
                    label: const Text('Download PDF', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: AppColors.slate200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.navy),
                    label: const Text('Share', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              secondary: true,
              onPressed: () => Navigator.of(context).pushNamed(Routes.consumerReport),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.message_outlined),
                SizedBox(width: 8),
                Text('Report an issue'),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
