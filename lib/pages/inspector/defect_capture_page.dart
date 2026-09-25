import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/colors.dart';
import '../../models/data.dart';
import '../../utils/exif_helper.dart';
import '../../services/socket_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/cloudinary_services.dart';
import '../../data/local/shared_prefs_helper.dart';
import 'schedule_x_notice_page.dart';

class DefectCapturePage extends StatefulWidget {
  final String inspectionId;
  final List<String> failedFields;

  const DefectCapturePage({
    super.key,
    required this.inspectionId,
    required this.failedFields,
  });

  @override
  State<DefectCapturePage> createState() =>
      _DefectCapturePageState();
}

class _DefectCapturePageState
    extends State<DefectCapturePage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  int _currentIndex = 0;
  final List<String> _defectUrls = [];
  bool _isUploading = false;

  File? _image;
  bool _captured = false;
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
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!
          .takePicture();

      final Position? position =
          await getCurrentDeviceLocation();
      double? lat = position?.latitude;
      double? lng = position?.longitude;

      if (lat != null && lng != null) {
        await writeGeoLocationToImage(photo.path, lat, lng);
      }

      final location = await getGeoLocationFromImage(
        photo.path,
      );
      if (location != null) {
        lat = location['latitude'];
        lng = location['longitude'];
      }

      final photoTime =
          await getImageOriginalDate(photo.path) ??
          DateTime.now();
      final hour = photoTime.hour % 12 == 0
          ? 12
          : photoTime.hour % 12;
      final minute = photoTime.minute.toString().padLeft(
        2,
        '0',
      );
      final second = photoTime.second.toString().padLeft(
        2,
        '0',
      );
      final period = photoTime.hour >= 12 ? 'PM' : 'AM';
      final formattedTime = '$hour:$minute:$second $period';

      setState(() {
        _image = File(photo.path);
        _captured = true;
        _latitude = lat;
        _longitude = lng;
        _capturedTime = formattedTime;
      });
    } catch (e) {
      debugPrint('Error capturing defect image: $e');
    }
  }

  void _retake() => setState(() {
    _captured = false;
    _image = null;
    _latitude = null;
    _longitude = null;
    _capturedTime = null;
  });

  double _haversineDistanceMetres(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;
    final a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) *
            cos(phi2) *
            sin(deltaLambda / 2) *
            sin(deltaLambda / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _showLocationMismatchPopup(double distanceM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.location_off_rounded,
              color: Colors.redAccent,
            ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
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

  Future<void> _handleNextOrSubmit() async {
    final expectedLoc = getInspectionLocation(
      widget.inspectionId,
    );
    if (expectedLoc != null &&
        _latitude != null &&
        _longitude != null) {
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

    setState(() => _isUploading = true);

    String? pathOrUrl;
    if (ConnectivityService().isOnline.value) {
      pathOrUrl = await CloudinaryService.uploadImage(
        _image!,
      );
      if (pathOrUrl == null) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to upload image. Try again.',
              ),
            ),
          );
        }
        return;
      }
    } else {
      pathOrUrl = _image!
          .path; // Store local path for offline queue
    }

    _defectUrls.add(pathOrUrl);

    if (_currentIndex < widget.failedFields.length - 1) {
      // Move to next defect
      setState(() {
        _isUploading = false;
        _currentIndex++;
        _captured = false;
        _image = null;
        _latitude = null;
        _longitude = null;
        _capturedTime = null;
      });
    } else {
      final item = inspectionFor(widget.inspectionId);
      final lmoId = item.assignedOfficerId ?? SocketService().officerUserId ?? 'UNKNOWN_LMO';
      final defectRemarks = widget.failedFields.join(', ');
      final tokenHash =
          'REJ_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}_${widget.inspectionId.replaceAll('-', '')}';

      final rejectionDataJson = {
        'applicationId': item.applicationId,
        'inspectorId': lmoId,
        'instrumentCategory': item.instrument,
        'instrumentSerialNumber': item.serial,
        'lat': _latitude ?? 0.0,
        'long': _longitude ?? 0.0,
        'sealImageUrls': _defectUrls,
        'defectImageUrls': _defectUrls,
        'defectReasons': widget.failedFields,
        'remarks': 'Visual checklist failed: $defectRemarks',
        'token_hash': tokenHash,
        'status': 'FAILED_CHECKLIST',
        'rectification_deadline': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'timeStamp': DateTime.now().microsecondsSinceEpoch,
      };

      // Emit rejection payload to socket server
      SocketService().emitInspectionRejected(rejectionDataJson);

      // Issue Schedule X Rejection in local storage
      final prefsHelper = SharedPrefsHelper();
      await prefsHelper.issueScheduleXRejection(
        inspectionId: widget.inspectionId,
        defectReasons: widget.failedFields,
        lmoId: lmoId,
        remarks: 'Visual checklist failed: $defectRemarks',
      );

      markInspectionRejected(widget.inspectionId); // Keep on home with deadline banner
      setState(() => _isUploading = false);

      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _DefectSubmittedSheet(
          inspectionId: widget.inspectionId,
          isOffline: !ConnectivityService().isOnline.value,
        ),
      );
      if (!mounted) return;
      // Navigate to Schedule X Notice instead of home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ScheduleXNoticePage(inspectionId: widget.inspectionId),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast =
        _currentIndex == widget.failedFields.length - 1;
    final currentField = widget.failedFields.isNotEmpty
        ? widget.failedFields[_currentIndex]
        : 'Unknown Field';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_captured && _image != null)
            Image.file(_image!, fit: BoxFit.cover)
          else if (_isCameraInitialized &&
              _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.saffron,
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _glassButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () =>
                        Navigator.of(context).pop(),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'DEFECT EVIDENCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentIndex + 1} OF ${widget.failedFields.length}',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
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
                      color: AppColors.errorRed.withValues(
                        alpha: 0.25,
                      ),
                      borderRadius: BorderRadius.circular(
                        999,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: const Text(
                      'FAILED',
                      style: TextStyle(
                        color: Color(0xFFFECACA),
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
              top:
                  MediaQuery.of(context).size.height * 0.14,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 40,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(
                        999,
                      ),
                    ),
                    child: const Text(
                      'Capture defect evidence for:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(
                        alpha: 0.85,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Text(
                      currentField,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!_captured)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  40,
                ),
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
                    GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.4,
                            ),
                            width: 5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white
                                  .withValues(alpha: 0.2),
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
                margin: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  32,
                ),
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
                          borderRadius:
                              BorderRadius.circular(10),
                          child: SizedBox(
                            height: 56,
                            width: 56,
                            child: _image != null
                                ? Image.file(
                                    _image!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _latitude != null &&
                                        _longitude != null
                                    ? 'GPS: ${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°'
                                    : 'Defect photo · Geo-tagged',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w800,
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
                              minimumSize:
                                  const Size.fromHeight(44),
                              backgroundColor:
                                  AppColors.slate100,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                      10,
                                    ),
                              ),
                            ),
                            onPressed: _isUploading
                                ? null
                                : _retake,
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
                              backgroundColor: isLast
                                  ? AppColors.errorRed
                                  : AppColors.navy,
                              minimumSize:
                                  const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                      10,
                                    ),
                              ),
                            ),
                            onPressed: _isUploading
                                ? null
                                : _handleNextOrSubmit,
                            child: _isUploading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              Colors.white,
                                        ),
                                  )
                                : Text(
                                    isLast
                                        ? 'Submit Defect'
                                        : 'Next Capture',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (_captured &&
              _latitude != null &&
              !_isUploading)
            Positioned(
              left: 16,
              bottom: 180,
              right: 16,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _gpsTag(
                    '${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°',
                  ),
                  if (_capturedTime != null)
                    _gpsTag(_capturedTime!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      height: 40,
      width: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );

  Widget _gpsTag(String text) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 5,
    ),
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

class _DefectSubmittedSheet extends StatelessWidget {
  final String inspectionId;
  final bool isOffline;
  const _DefectSubmittedSheet({
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
              color: isOffline
                  ? AppColors.amber50
                  : AppColors.red50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOffline
                  ? Icons.cloud_off_rounded
                  : Icons.warning_rounded,
              color: isOffline
                  ? AppColors.amber
                  : AppColors.errorRed,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isOffline
                ? 'Defect Queued for Sync'
                : 'Defect Logged Successfully',
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOffline
                ? 'Defect evidence saved locally. Please sync when online.'
                : 'Defect evidence geo-tagged and marked failed.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate,
            ),
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
