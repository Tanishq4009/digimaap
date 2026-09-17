import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../routes.dart';

class InspectorProfilePage extends StatefulWidget {
  const InspectorProfilePage({super.key});

  @override
  State<InspectorProfilePage> createState() => _InspectorProfilePageState();
}

class _InspectorProfilePageState extends State<InspectorProfilePage> {
  String language = 'English';
  bool wifiOnly = true;

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.inspector,
      title: 'Inspector profile',
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
                      Text('Rajesh Kumar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      SizedBox(height: 3),
                      Text('LMO-MP-1048 · Legal Metrology Officer', style: TextStyle(fontSize: 12, color: AppColors.slate)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jurisdiction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  SizedBox(height: 4),
                  Text('Bhopal Circle · Madhya Pradesh', style: TextStyle(fontSize: 12, color: AppColors.slate)),
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
                  InkWell(
                    onTap: () => setState(() => language = language == 'English' ? 'हिन्दी' : 'English'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          Text(language, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.slate100),
                  InkWell(
                    onTap: () => setState(() => wifiOnly = !wifiOnly),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sync preference', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          Text(wifiOnly ? 'Wi-Fi only' : 'Any network', style: const TextStyle(fontSize: 12, color: AppColors.slate)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const FooterStrip(),
            const SizedBox(height: 16),
            PrimaryButton(
              secondary: true,
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.entry, (r) => false),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
