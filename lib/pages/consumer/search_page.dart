import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../routes.dart';
import 'certificate_result_page.dart';

class SearchCertificatePage extends StatefulWidget {
  const SearchCertificatePage({super.key});

  @override
  State<SearchCertificatePage> createState() => _SearchCertificatePageState();
}

class _SearchCertificatePageState extends State<SearchCertificatePage> {
  final _controller = TextEditingController();
  bool searched = false;

  CertificateData? get match {
    final value = _controller.text.trim();
    for (final item in certificates.values) {
      if (item.number == value) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final result = searched ? match : null;
    return Shell(
      role: AppRole.consumer,
      title: 'Search certificate',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find a certificate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text(
              'Enter the number printed on the certificate or instrument.',
              style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.slate400, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (_) => setState(() => searched = false),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'LM/DL/2026/00452',
                        hintStyle: TextStyle(color: AppColors.slate400, fontSize: 13),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              onPressed: () => setState(() => searched = true),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Search certificate'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ]),
            ),
            if (searched) ...[
              const SizedBox(height: 20),
              if (result != null)
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CertificateResultPage(certId: result.id)),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.green50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.green100),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Certificate found', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                              const SizedBox(height: 2),
                              Text('${result.instrument} · View verified record', style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.red50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.red200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Certificate not found', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.errorRed)),
                            const SizedBox(height: 4),
                            const Text(
                              'Check the number or report a possible counterfeit.',
                              style: TextStyle(fontSize: 12, color: AppColors.slate, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              onPressed: () => Navigator.of(context).pushNamed(Routes.consumerReport),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('Report to Legal Metrology', style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w800, fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: AppColors.errorRed, size: 13),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
