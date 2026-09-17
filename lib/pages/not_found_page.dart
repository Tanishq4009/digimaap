import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../routes.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('404', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('Oops! Page not found', style: TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.entry, (r) => false),
              child: const Text('Return to Home', style: TextStyle(color: AppColors.navy, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}
