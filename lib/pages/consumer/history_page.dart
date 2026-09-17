import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import 'certificate_result_page.dart';

class ConsumerHistoryPage extends StatefulWidget {
  const ConsumerHistoryPage({super.key});

  @override
  State<ConsumerHistoryPage> createState() => _ConsumerHistoryPageState();
}

class _ConsumerHistoryPageState extends State<ConsumerHistoryPage> {
  final _query = TextEditingController();
  bool extra = false;

  @override
  Widget build(BuildContext context) {
    final q = _query.text.toLowerCase();
    final rows = certificates.values
        .where((item) => '${item.instrument} ${item.number}'.toLowerCase().contains(q))
        .toList();

    return Shell(
      role: AppRole.consumer,
      title: 'Scan history',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.slate400, size: 17),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'Search records'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < rows.length; i++) ...[
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CertificateResultPage(certId: rows[i].id)),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rows[i].status == 'expired' ? AppColors.red50 : AppColors.green50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.fact_check_outlined,
                            color: rows[i].status == 'expired' ? AppColors.errorRed : AppColors.success, size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rows[i].instrument, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                            const SizedBox(height: 3),
                            Text('${rows[i].number} · ${i == 0 ? 'Today' : '05 Jan 2026'}',
                                style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (extra) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Text('Older record · Industrial Platform Scale',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              const SizedBox(height: 12),
            ],
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => extra = true),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.navy),
                label: Text(
                  extra ? 'All records loaded' : 'Load older records',
                  style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
