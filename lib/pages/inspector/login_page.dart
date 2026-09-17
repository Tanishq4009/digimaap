import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../routes.dart';

class InspectorLoginPage extends StatefulWidget {
  const InspectorLoginPage({super.key});

  @override
  State<InspectorLoginPage> createState() => _InspectorLoginPageState();
}

class _InspectorLoginPageState extends State<InspectorLoginPage> {
  final _id = TextEditingController();
  final _dept = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Shell(
      nav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.navy, size: 18),
              ),
            ),
            const SizedBox(height: 40),
            const Brand(),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(999)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: AppColors.navy),
                  SizedBox(width: 6),
                  Text('OFFICER SECURE ACCESS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Field officer login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text(
              'Use your department credentials to access assigned inspections.',
              style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.5),
            ),
            const SizedBox(height: 24),
            AppField(label: 'Employee ID', placeholder: 'LMO-MP-1048', controller: _id),
            const SizedBox(height: 16),
            AppField(label: 'Department', placeholder: 'Legal Metrology, Madhya Pradesh', controller: _dept),
            const SizedBox(height: 16),
            AppField(label: 'Password', placeholder: '••••••••••', controller: _password, obscureText: true),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.inspectorHome, (r) => false),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Continue'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
