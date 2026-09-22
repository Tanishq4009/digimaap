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
                      decoration: const BoxDecoration(color: AppColors.red100, shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text('TAMPERED / INVALID CERTIFICATE', textAlign: TextAlign.center, style: TextStyle(color: AppColors.errorRed, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('No valid record found for this certificate number.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                onPressed: () => Navigator.of(context).pushNamed(Routes.consumerReport),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.report_problem_outlined),
                  SizedBox(width: 8),
                  Text('Report Violation / Short Weighing'),
                ]),
              ),
            ],
          ),
        ),
      );
    }

    final expired = forceExpired || item.status == 'expired';

    Color headerBgColor = expired ? AppColors.orange50 : AppColors.green50;
    Color headerBorderColor = expired ? AppColors.orange200 : AppColors.green100;
    Color headerIconColor = expired ? AppColors.saffron : AppColors.success;
    String headerText = expired ? 'VERIFICATION EXPIRED' : 'VERIFIED / LEGALLY VALID';
    IconData headerIcon = expired ? Icons.warning_amber_rounded : Icons.check_circle_rounded;

    return Shell(
      role: AppRole.consumer,
      title: 'Certificate result',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level 1: Top Header - Instant Status Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: headerBorderColor, width: 2),
              ),
              child: Column(
                children: [
                  Icon(headerIcon, color: headerIconColor, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    headerText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: headerIconColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Level 2: Middle Section - Human-Readable Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MERCHANT & LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate)),
                  const SizedBox(height: 8),
                  Text(item.merchantName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(item.address, style: const TextStyle(fontSize: 13, color: AppColors.slate)),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.slate200, height: 1),
                  ),
                  
                  const Text('INSTRUMENT SPECIFICATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate)),
                  const SizedBox(height: 12),
                  _buildDetailRow('Category', item.category),
                  _buildDetailRow('Serial Number', item.serial),
                  _buildDetailRow('Accuracy Class', item.accuracyClass),
                  _buildDetailRow('Max Capacity', item.capacity),
                  _buildDetailRow('Scale Interval (e)', item.scaleInterval),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.slate200, height: 1),
                  ),

                  const Text('VALIDITY DATES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate)),
                  const SizedBox(height: 12),
                  _buildDetailRow('Last Verification', item.issueDate),
                  _buildDetailRow('Expiry Date', item.expiryDate, isError: expired),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.slate200, height: 1),
                  ),

                  const Text('INSPECTOR DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate)),
                  const SizedBox(height: 12),
                  _buildDetailRow('Verified By', '${item.inspectorName} (${item.inspectorId})'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Level 3: Bottom Action Buttons
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.navy, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // View PDF Logic
              },
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.navy),
              label: const Text('View Official eSigned Certificate (PDF)', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              secondary: !expired,
              onPressed: () => Navigator.of(context).pushNamed(Routes.consumerReport),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.report_problem_outlined),
                SizedBox(width: 8),
                Text('Report Violation / Short Weighing'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value, 
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w600, 
                color: isError ? AppColors.saffron : AppColors.ink,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
