import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../routes.dart';
import 'certificate_result_page.dart';

class ConsumerHomePage extends StatelessWidget {
  const ConsumerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.consumer,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Namaste, Citizen', style: TextStyle(color: AppColors.blue100, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('Verify with confidence.',
                                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pushNamed(Routes.consumerProfile),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 44,
                          width: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: AppColors.blue100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroCard,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CERTIFICATE VERIFICATION',
                                      style: TextStyle(color: AppColors.blue100, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                  SizedBox(height: 10),
                                  Text('Is your instrument certified?',
                                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
                                  SizedBox(height: 8),
                                  Text('Scan the QR code to check its legal status instantly.',
                                      style: TextStyle(color: AppColors.blue100, fontSize: 12, height: 1.4)),
                                ],
                              ),
                            ),
                            Container(
                              height: 60,
                              width: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 34),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          onPressed: () => Navigator.of(context).pushNamed(Routes.consumerScan),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.qr_code_scanner_rounded),
                            SizedBox(width: 8),
                            Text('SCAN QR CODE'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed(Routes.consumerSearch),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.navy, size: 18),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Search by Certificate Number',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate)),
                          ),
                          Icon(Icons.arrow_forward, color: AppColors.slate, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent scans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed(Routes.consumerHistory),
                        child: const Text('View all', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CertificateResultPage(certId: certificate.id)),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.fact_check_outlined, color: AppColors.success, size: 21),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(certificate.instrument,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                const SizedBox(height: 4),
                                Text('${certificate.number} · Today, 10:42 AM',
                                    style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(999)),
                            child: const Text('VALID', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFFFFF4E9), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_outlined, color: AppColors.saffron, size: 16),
                            SizedBox(width: 8),
                            Text('KNOW YOUR RIGHTS',
                                style: TextStyle(color: AppColors.saffron, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('What does a valid DigiMaap certificate mean?',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        const SizedBox(height: 8),
                        const Text(
                          'Every certified instrument is checked, sealed and recorded by Legal Metrology.',
                          style: TextStyle(fontSize: 12, color: AppColors.slate, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          onPressed: () => Navigator.of(context).pushNamed(Routes.help),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Learn more', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: AppColors.navy, size: 13),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
