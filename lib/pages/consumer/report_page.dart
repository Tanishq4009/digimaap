import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../routes.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.consumer,
      title: submitted ? 'Report submitted' : 'Report an issue',
      child: submitted ? _submitted(context) : _form(),
    );
  }

  Widget _submitted(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.green100, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Report submitted', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 13, color: AppColors.slate),
              children: [
                TextSpan(text: 'Reference ID: '),
                TextSpan(text: 'RPT-260112-0042', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.consumerHome, (r) => false),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(certificate.number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 4),
                const Text('Help us keep measurements fair', style: TextStyle(fontSize: 12, color: AppColors.slate)),
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
              decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'Describe what happened...'),
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.slate200, style: BorderStyle.solid),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.description_outlined, color: AppColors.navy, size: 17),
            label: const Text('Attach photo evidence', style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            onPressed: () => setState(() => submitted = true),
            child: const Text('Submit securely'),
          ),
        ],
      ),
    );
  }
}
