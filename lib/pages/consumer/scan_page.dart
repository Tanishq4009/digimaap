import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../routes.dart';
import 'certificate_result_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool flash = false;

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.consumer,
      title: 'Scan certificate',
      nav: false,
      backgroundColor: AppColors.scanBg,
      child: Container(
        color: flash ? const Color(0xFF39404A) : AppColors.scanBg,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleBtn(Icons.close_rounded, () => Navigator.of(context).pop()),
                const Text('QR VERIFIER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
                _circleBtn(
                  Icons.flash_on_rounded,
                  () => setState(() => flash = !flash),
                  active: flash,
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 240,
              width: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const QRPattern(),
                  ),
                  _corner(Alignment.topLeft),
                  _corner(Alignment.topRight),
                  _corner(Alignment.bottomLeft),
                  _corner(Alignment.bottomRight),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Align QR code within the frame',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            const Text(
              "We'll verify the certificate against the live Legal Metrology record.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _option(Icons.image_outlined, 'Gallery', () {}),
                const SizedBox(width: 24),
                _option(Icons.keyboard_alt_outlined, 'Enter manually', () => Navigator.of(context).pushNamed(Routes.consumerSearch)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CertificateResultPage(certId: certificate.id)),
                ),
                child: const Text('Scan QR code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    final isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    return Align(
      alignment: alignment,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.saffron, width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.saffron, width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.saffron, width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.saffron, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool active = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.saffron : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  Widget _option(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white70, size: 19),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
