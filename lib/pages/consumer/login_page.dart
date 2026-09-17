import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../routes.dart';

class ConsumerLoginPage extends StatefulWidget {
  const ConsumerLoginPage({super.key});

  @override
  State<ConsumerLoginPage> createState() => _ConsumerLoginPageState();
}

class _ConsumerLoginPageState extends State<ConsumerLoginPage> {
  final _mobile = TextEditingController();

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
            const SizedBox(height: 36),
            const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            const Text(
              'Sign in to keep your certificate history synced.',
              style: TextStyle(fontSize: 13, color: AppColors.slate),
            ),
            const SizedBox(height: 24),
            AppField(label: 'Mobile number', placeholder: '98765 43210', controller: _mobile),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.consumerHome, (r) => false),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Continue'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ]),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed(Routes.consumerScan),
                child: const Text('Continue as Guest', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
