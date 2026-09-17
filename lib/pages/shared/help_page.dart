import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _query = TextEditingController();
  int? open;

  static const _faqs = [
    ['How do I verify a certificate?', 'Scan the QR code or enter the certificate number. eMaap checks the live government record.'],
    ['What does Verified mean?', 'The certificate is active, issued by Legal Metrology, and seal evidence matches the digital record.'],
    ['What if the certificate is expired?', 'Do not rely on the instrument for trade. Report it to your nearest Legal Metrology office.'],
    ['Why is verification unavailable offline?', 'Verification requires a live connection to protect you from outdated or tampered records.'],
    ['How are officer photos secured?', 'Seal photos are timestamped, geo-tagged and linked to a SHA-256 secured record.'],
  ];

  @override
  Widget build(BuildContext context) {
    final q = _query.text.toLowerCase();
    final shown = _faqs.where((f) => '${f[0]} ${f[1]}'.toLowerCase().contains(q)).toList();

    return Shell(
      role: AppRole.consumer,
      title: 'Help & FAQ',
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
                      decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'Search questions'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < shown.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => open = open == i ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(shown[i][0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                            ),
                            Icon(open == i ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.slate),
                          ],
                        ),
                      ),
                    ),
                    if (open == i)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(shown[i][1], style: const TextStyle(fontSize: 12, color: AppColors.slate, height: 1.5)),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline_rounded, color: AppColors.saffron, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact Legal Metrology Office', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('Need help with a measurement or certificate?', style: TextStyle(color: AppColors.blue100, fontSize: 12)),
                        const SizedBox(height: 10),
                        const Text('1800 180 0180', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
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
