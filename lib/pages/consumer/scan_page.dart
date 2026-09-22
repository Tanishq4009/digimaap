import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../routes.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() => _isProcessing = true);
    await _scannerController.stop();

    try {
      final Uri uri = Uri.parse(rawValue);
      
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Official Verification Portal...'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) {
            Navigator.of(context).pop(); // Return to consumer home
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch the verification URL.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
          _resumeScanning();
        }
      } else {
        _showInvalidQRMessage();
      }
    } catch (e) {
      _showInvalidQRMessage();
    }
  }

  void _showInvalidQRMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid Legal Metrology QR Code. Please scan an official scale QR.'),
        backgroundColor: AppColors.errorRed,
        duration: Duration(seconds: 3),
      ),
    );
    _resumeScanning();
  }

  void _resumeScanning() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.consumer,
      title: 'Scan certificate',
      nav: false,
      backgroundColor: AppColors.scanBg,
      child: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Camera error: ${error.errorCode.name}\nPlease ensure camera permissions are granted.',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          
          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circleBtn(Icons.close_rounded, () => Navigator.of(context).pop()),
                      const Text('QR VERIFIER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
                      Row(
                        children: [
                          _circleBtn(
                            Icons.cameraswitch_rounded,
                            () => _scannerController.switchCamera(),
                          ),
                          const SizedBox(width: 12),
                          _circleBtn(
                            Icons.flash_on_rounded,
                            () {
                              setState(() => _flashOn = !_flashOn);
                              _scannerController.toggleTorch();
                            },
                            active: _flashOn,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Scanner Frame Overlay
                SizedBox(
                  height: 280,
                  width: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
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
                
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _option(Icons.image_outlined, 'Gallery', () {}),
                      const SizedBox(width: 24),
                      _option(Icons.keyboard_alt_outlined, 'Enter manually', () => Navigator.of(context).pushNamed(Routes.consumerSearch)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.saffron),
              ),
            ),
        ],
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
          color: active ? AppColors.saffron : Colors.white.withValues(alpha: 0.2),
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
