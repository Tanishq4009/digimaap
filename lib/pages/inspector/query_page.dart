import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../routes.dart';

class InspectorQueryPage extends StatelessWidget {
  const InspectorQueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.inspector,
      title: 'Raise a query',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Query for inspection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  SizedBox(height: 4),
                  Text('Evidence has been attached from the field inspection.', style: TextStyle(fontSize: 12, color: AppColors.slate)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 112,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const TextField(
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'Describe the deficiency...'),
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.inspectorHome, (r) => false),
              child: const Text('Submit query'),
            ),
          ],
        ),
      ),
    );
  }
}
