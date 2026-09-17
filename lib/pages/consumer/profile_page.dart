import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String language = 'English';
  bool picker = false;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['Language', language],
      ['Notifications', 'On'],
      ['Help & FAQ', 'Get support'],
      ['Privacy Policy', 'Read policy'],
    ];

    return Shell(
      role: AppRole.consumer,
      title: 'Profile & settings',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.blue50, shape: BoxShape.circle),
                    child: const Icon(Icons.person_outline_rounded, color: AppColors.navy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Citizen account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      SizedBox(height: 3),
                      Text('Verified mobile · +91 98765 43210', style: TextStyle(fontSize: 12, color: AppColors.slate)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < rows.length; i++) ...[
                    InkWell(
                      onTap: () {
                        if (i == 0) setState(() => picker = !picker);
                        if (i == 2) Navigator.of(context).pushNamed(Routes.help);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(rows[i][0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            Row(
                              children: [
                                Text(rows[i][1], style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.slate),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i != rows.length - 1) const Divider(height: 1, color: AppColors.slate100),
                  ],
                  if (picker)
                    Container(
                      color: AppColors.blue50,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _langBtn('English', language == 'English', () => setState(() { language = 'English'; picker = false; })),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _langBtn('हिन्दी', language == 'हिन्दी', () => setState(() { language = 'हिन्दी'; picker = false; })),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const FooterStrip(),
          ],
        ),
      ),
    );
  }

  Widget _langBtn(String label, bool active, VoidCallback onTap) {
    return Material(
      color: active ? AppColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: active ? Colors.white : AppColors.navy, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
