import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/common.dart';
import '../routes.dart';

class EntryPage extends StatelessWidget {
  const EntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Shell(
      nav: false,
      backgroundColor: AppColors.navy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: AppColors.blue100),
                  SizedBox(width: 6),
                  Text(
                    'GOVERNMENT OF INDIA DIGITAL SERVICE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.blue100, letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Trust what\nyou measure.',
              style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.1),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 260,
              child: Text(
                'Verify certificates and manage field inspections securely with DigiMaap.',
                style: TextStyle(color: AppColors.blue100, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'CONTINUE AS',
              style: TextStyle(color: AppColors.blue100, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.qr_code_rounded,
              iconBg: AppColors.blue50,
              iconFg: AppColors.navy,
              title: 'Consumer / Business',
              subtitle: 'Verify a certificate',
              filled: true,
              onTap: () => Navigator.of(context).pushNamed(Routes.consumerLogin),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.verified_user_rounded,
              iconBg: AppColors.saffron,
              iconFg: Colors.white,
              title: 'Legal Metrology Officer',
              subtitle: 'Field login & inspections',
              filled: false,
              onTap: () => Navigator.of(context).pushNamed(Routes.inspectorLogin),
            ),
            const SizedBox(height: 40),
            const Text(
              'Secure · Transparent · Made for India',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.blue100, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = filled ? AppColors.ink : Colors.white;
    final Color subColor = filled ? AppColors.slate : AppColors.blue100;
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconFg, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: subColor, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subColor),
            ],
          ),
        ),
      ),
    );
  }
}
