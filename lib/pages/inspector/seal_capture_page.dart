import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import '../../models/data.dart';
import '../../models/seal_type.dart';
import '../../utils/exif_helper.dart';
import '../../services/socket_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/cloudinary_services.dart';
import '../../services/image_cropper.dart';

// ─────────────────────────────────────────────────────────────────────────
// Smart Overlay Painter — dark mask with a real transparent cutout window.
// The cutout MUST be drawn inside a saveLayer/restore pair: BlendMode.clear
// only punches a hole through content painted in the SAME layer. Skip the
// saveLayer and the "clear" either does nothing or wipes more than the
// cutout depending on the surrounding repaint boundary.
//
// IMPORTANT: the rect sizes/center here (110 / 210 / 300x130, cy = 0.42*h)
// are duplicated in ImageCropperService._cutoutRectForScreen — if you
// change the guide here, change it there too, or the crop will drift from
// what the user actually saw on screen.
// ─────────────────────────────────────────────────────────────────────────

class SmartOverlayPainter extends CustomPainter {
  final SealType sealType;
  SmartOverlayPainter({required this.sealType});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    final maskPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.62)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), maskPaint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    switch (sealType) {
      case SealType.lead:
        canvas.drawCircle(Offset(cx, cy), 110, clearPaint);
      case SealType.punch:
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: 210, height: 210),
          clearPaint,
        );
      case SealType.sticker:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 300, height: 130),
            const Radius.circular(12),
          ),
          clearPaint,
        );
    }

    canvas.restore();

    final borderPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    switch (sealType) {
      case SealType.lead:
        canvas.drawCircle(Offset(cx, cy), 110, borderPaint);
      case SealType.punch:
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: 210, height: 210),
          borderPaint,
        );
      case SealType.sticker:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 300, height: 130),
            const Radius.circular(12),
          ),
          borderPaint,
        );
    }

    if (sealType != SealType.lead) {
      _drawCornerTicks(canvas, cx, cy, borderPaint);
    }
  }

  void _drawCornerTicks(Canvas canvas, double cx, double cy, Paint p) {
    final hw = sealType == SealType.punch ? 105.0 : 150.0;
    final hh = sealType == SealType.punch ? 105.0 : 65.0;
    const len = 18.0;

    final corners = [
      Offset(cx - hw, cy - hh),
      Offset(cx + hw, cy - hh),
      Offset(cx - hw, cy + hh),
      Offset(cx + hw, cy + hh),
    ];
    final dx = [len, -len, len, -len];
    final dy = [len, len, -len, -len];

    for (var i = 0; i < corners.length; i++) {
      canvas.drawLine(
        corners[i],
        Offset(corners[i].dx + dx[i], corners[i].dy),
        p,
      );
      canvas.drawLine(
        corners[i],
        Offset(corners[i].dx, corners[i].dy + dy[i]),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SmartOverlayPainter old) =>
      old.sealType != sealType;
}

// ─────────────────────────────────────────────────────────────────────────
// SealCapturePage
// ─────────────────────────────────────────────────────────────────────────

class SealCapturePage extends StatefulWidget {
  final String inspectionId;
  const SealCapturePage({
    super.key,
    required this.inspectionId,
  });

  @override
  State<SealCapturePage> createState() => _SealCapturePageState();
}

class _SealCapturePageState extends State<SealCapturePage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  SealType _sealType = SealType.lead;

  File? _croppedImage; // what we show + upload — never the raw uncropped shot
  bool _captured = false;
  bool _uploading = false;
  double? _latitude;
  double? _longitude;
  String? _capturedTime;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _warmUpLocation();
  }

  Future<void> _warmUpLocation() async {
    await getCurrentDeviceLocation();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Capture + auto-crop ─────────────────────────────────────────────

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final photo = await _cameraController!.takePicture();

      final position = await getCurrentDeviceLocation();
      double? lat = position?.latitude;
      double? lng = position?.longitude;

      if (lat != null && lng != null) {
        await writeGeoLocationToImage(photo.path, lat, lng);
      }
      final location = await getGeoLocationFromImage(photo.path);
      if (location != null) {
        lat = location['latitude'];
        lng = location['longitude'];
      }

      final photoTime =
          await getImageOriginalDate(photo.path) ?? DateTime.now();
      final hour = photoTime.hour % 12 == 0 ? 12 : photoTime.hour % 12;
      final minute = photoTime.minute.toString().padLeft(2, '0');
      final second = photoTime.second.toString().padLeft(2, '0');
      final period = photoTime.hour >= 12 ? 'PM' : 'AM';
      final formattedTime = '$hour:$minute:$second $period';

      // Crop down to exactly the cutout the user saw — this is what gets
      // shown for review AND what gets uploaded, so nothing outside the
      // guide shape ever leaves the device.
      final cropped = await ImageCropperService.cropImage(
        File(photo.path),
        _sealType,
      );

      if (cropped == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not process the photo. Please try again.'),
          ),
        );
        return;
      }

      setState(() {
        _croppedImage = cropped;
        _captured = true;
        _latitude = lat;
        _longitude = lng;
        _capturedTime = formattedTime;
      });
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  void _retake() => setState(() {
    _captured = false;
    _croppedImage = null;
    _latitude = null;
    _longitude = null;
    _capturedTime = null;
  });

  // ── Haversine ────────────────────────────────────────────────────────

  double _haversineDistanceMetres(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dPhi = (lat2 - lat1) * pi / 180;
    final dLambda = (lon2 - lon1) * pi / 180;
    final a =
        sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _showLocationMismatchPopup(double distanceM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Location Mismatch',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are ${distanceM.toStringAsFixed(0)}m away from the device location.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please go near the device and click the photo within 100 metres of the registered address.',
              style: TextStyle(color: AppColors.slate),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffron,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUploadFailedPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Upload Failed',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: const Text(
          'Could not upload the seal photo to the cloud. Check your connection and try again.',
          style: TextStyle(color: AppColors.slate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Submit: upload to Cloudinary, then send the URL over the socket ──

  Future<void> _submit() async {
    if (_croppedImage == null) return;

    final expectedLoc = getInspectionLocation(widget.inspectionId);
    if (expectedLoc != null && _latitude != null && _longitude != null) {
      final distanceM = _haversineDistanceMetres(
        expectedLoc['lat']!,
        expectedLoc['lng']!,
        _latitude!,
        _longitude!,
      );
      if (distanceM > 100) {
        _showLocationMismatchPopup(distanceM);
        return;
      }
    }

    final item = inspectionFor(widget.inspectionId);
    final isOnline = ConnectivityService().isOnline.value;

    if (!isOnline) {
      // No internet -> Cloudinary upload is impossible right now. Queue the
      // cropped file's local path + metadata; the sync flow should re-run
      // the same upload + emit when connectivity returns.
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_inspections') ?? [];
      final tokenHash =
          'LMO_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}_${widget.inspectionId.replaceAll('-', '')}';

      final wrapper = {
        'inspectionId': widget
            .inspectionId, // We need inspectionId to mark it properly later
        'instrumentCategory': item.instrument,
        'instrumentSerialNumber': item.serial,
        'lat': _latitude ?? 0.0,
        'long': _longitude ?? 0.0,
        'sealImageUrls': [
          _croppedImage!.path,
        ], // Storing LOCAL path when offline
        'token_hash': tokenHash,
        'status': 'APPROVED_CHECKLIST',
        'timeStamp': DateTime.now().microsecondsSinceEpoch,
      };
      pending.add(jsonEncode(wrapper));
      await prefs.setStringList('pending_inspections', pending);

      markInspectionDone(widget.inspectionId);
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _SealSubmittedSheet(
          inspectionId: widget.inspectionId,
          isOffline: true,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _uploading = true);
    final List<String?> cloudUrl = [];
    final String? cloud = await CloudinaryService.uploadImage(_croppedImage!);
    if (!mounted) return;
    setState(() => _uploading = false);

    if (cloud == null) {
      _showUploadFailedPopup();
      return;
    }

    cloudUrl.add(cloud);

    final tokenHash =
        'LMO_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}_${widget.inspectionId.replaceAll('-', '')}';

    final sealDataJson = {
      'instrumentCategory': item.instrument,
      'instrumentSerialNumber': item.serial,
      'lat': _latitude ?? 0.0,
      'long': _longitude ?? 0.0,
      'sealImageUrls': cloudUrl,
      'token_hash': tokenHash,
      'status': 'APPROVED_CHECKLIST',
      'timeStamp': DateTime.now().microsecondsSinceEpoch,
    };

    saveSealEvidence(item.id, SealEvidence.fromJson(sealDataJson));
    SocketService().emitInspectionApproved(sealDataJson);
    markInspectionDone(widget.inspectionId);

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SealSubmittedSheet(
        inspectionId: widget.inspectionId,
        isOffline: false,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Full-bleed camera preview (BoxFit.cover behaviour) ────────────────
  // Required so the geometry ImageCropperService assumes (screen-space
  // cutout maps onto a "cover" viewport of the raw photo) is actually true.

  Widget _buildCoverCameraPreview(BuildContext context) {
    final controller = _cameraController!;
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return Transform.scale(
      scale: scale,
      child: Center(child: CameraPreview(controller)),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final item = inspectionFor(widget.inspectionId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_captured && _croppedImage != null)
            Image.file(_croppedImage!, fit: BoxFit.contain)
          else if (_isCameraInitialized && _cameraController != null)
            _buildCoverCameraPreview(context)
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.saffron),
            ),

          if (!_captured)
            CustomPaint(painter: SmartOverlayPainter(sealType: _sealType)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _glassButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SEAL EVIDENCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.serial,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Text(
                      'GEO-TAGGED',
                      style: TextStyle(
                        color: Color(0xFFBBF7D0),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!_captured)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.14,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Place the seal strictly inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (!_captured)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _sealChip(
                          'Lead Seal',
                          SealType.lead,
                          Icons.circle_outlined,
                        ),
                        const SizedBox(width: 10),
                        _sealChip(
                          'Metal Punch',
                          SealType.punch,
                          Icons.crop_square_rounded,
                        ),
                        const SizedBox(width: 10),
                        _sealChip(
                          'Sticker',
                          SealType.sticker,
                          Icons.rectangle_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 56,
                            width: 56,
                            child: _croppedImage != null
                                ? Image.file(_croppedImage!, fit: BoxFit.cover)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _latitude != null && _longitude != null
                                    ? 'GPS: ${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°'
                                    : 'Seal photo · Geo-tagged',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _capturedTime != null
                                    ? 'Timestamped · $_capturedTime'
                                    : 'Timestamped',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              backgroundColor: AppColors.slate100,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _uploading ? null : _retake,
                            child: const Text(
                              'Retake',
                              style: TextStyle(
                                color: AppColors.slate,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.saffron,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _uploading ? null : _submit,
                            child: _uploading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Use photo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (_uploading) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Uploading to secure cloud…',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          if (_captured && _latitude != null)
            Positioned(
              left: 16,
              bottom: 210,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _gpsTag(
                    '${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°',
                  ),
                  if (_capturedTime != null) _gpsTag(_capturedTime!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  Widget _sealChip(String label, SealType type, IconData icon) {
    final active = _sealType == type;
    return GestureDetector(
      onTap: () => setState(() => _sealType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.navy : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.navy : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gpsTag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Seal Submitted Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────

class _SealSubmittedSheet extends StatelessWidget {
  final String inspectionId;
  final bool isOffline;
  const _SealSubmittedSheet({
    required this.inspectionId,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final item = inspectionFor(inspectionId);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isOffline ? AppColors.amber50 : AppColors.green50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOffline ? Icons.cloud_off_rounded : Icons.check_circle_rounded,
              color: isOffline ? AppColors.amber : AppColors.success,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isOffline ? 'Added to Sync Queue' : 'Inspection Submitted',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.business} · $inspectionId',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.slate),
          ),
          const SizedBox(height: 4),
          Text(
            isOffline
                ? 'Seal photo saved locally. It will upload and sync automatically once you\'re back online.'
                : 'Seal evidence uploaded, geo-tagged and submitted successfully.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.slate),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffron,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}