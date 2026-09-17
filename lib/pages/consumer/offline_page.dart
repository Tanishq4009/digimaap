import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../routes.dart';

class ConsumerOfflinePage extends StatelessWidget {
  const ConsumerOfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.consumer,
      title: 'Connection unavailable',
      nav: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.amber50, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, color: AppColors.amber, size: 34),
              ),
              const SizedBox(height: 24),
              const Text("You're offline", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 12),
              const Text(
                "Certificate verification needs an internet connection. Try again once you're connected.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.slate, height: 1.5),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                onPressed: () => Navigator.of(context).pushNamed(Routes.consumerScan),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.wifi_rounded),
                  SizedBox(width: 8),
                  Text('Try again'),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
