import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../utils/exif_helper.dart';
import '../../services/socket_service.dart';
import '../../services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> convertImageToBase64(File? imageFile) async {
  if (imageFile == null) return '';
  List<int> imageBytes = await imageFile.readAsBytes();
  return base64Encode(imageBytes);
}

class SealCapturePage extends StatefulWidget {
  final String inspectionId;
  const SealCapturePage({super.key, required this.inspectionId});

  @override
  State<SealCapturePage> createState() => _SealCapturePageState();
}

class _SealCapturePageState extends State<SealCapturePage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  File? _image;
  bool captured = false;
  double? _latitude;
  double? _longitude;
  String? _capturedTime;
  Map<String, dynamic>? _sealDataJson;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _warmUpLocation();
  }

  Future<void> _warmUpLocation() async {
    await getCurrentDeviceLocation();
  }

  // Camera initialize karne ke liye helper function
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first, // Back Camera
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();

      // 1. Device se live GPS coordinates fetch karo
      final Position? position = await getCurrentDeviceLocation();
      double? lat = position?.latitude;
      double? lng = position?.longitude;

      // 2. Agar device GPS mila, toh image ke EXIF me embed/write kar do
      if (lat != null && lng != null) {
        debugPrint(
          "Device GPS found -> Lat: $lat, Lng: $lng. Writing to Image EXIF...",
        );
        await writeGeoLocationToImage(photo.path, lat, lng);
      }

      // 3. Ab image ke EXIF se read karo (100% verified geo-tag)
      final location = await getGeoLocationFromImage(photo.path);

      if (location != null) {
        lat = location['latitude'];
        lng = location['longitude'];
        debugPrint(
          "Successfully extracted from Image EXIF -> Lat: $lat, Lng: $lng",
        );
      } else if (lat != null && lng != null) {
        debugPrint("Using device coordinates -> Lat: $lat, Lng: $lng");
      } else {
        debugPrint(
          "Image me location data nahi mila (Shayad Location permission off thi ya GPS off tha).",
        );
      }

      final photoTime =
          await getImageOriginalDate(photo.path) ?? DateTime.now();
      final hour = photoTime.hour % 12 == 0 ? 12 : photoTime.hour % 12;
      final minute = photoTime.minute.toString().padLeft(2, '0');
      final second = photoTime.second.toString().padLeft(2, '0');
      final period = photoTime.hour >= 12 ? 'PM' : 'AM';
      final formattedTime = '$hour:$minute:$second $period';

      final imageFile = File(photo.path);
      final sealImageBase64 = await convertImageToBase64(imageFile);
      final item = inspectionFor(widget.inspectionId);

      // JSON format me exact key-value pairs
      final Map<String, dynamic> sealDataJson = {
        'instrumentCategory': item.instrument,
        'instrumentSerialNumber': item.serial,
        'lat': lat ?? 0.0,
        'long': lng ?? 0.0,
        'sealImageBase64': sealImageBase64,
      };

      // Store in memory repository
      saveSealEvidence(item.id, SealEvidence.fromJson(sealDataJson));

      debugPrint("=== SEAL EVIDENCE JSON STORED ===");
      debugPrint("instrumentCategory: ${sealDataJson['instrument']}");
      debugPrint("lat: ${sealDataJson['lat']}");
      debugPrint("long: ${sealDataJson['long']}");
      debugPrint("sealImageBase64: length ${sealImageBase64.length} chars");

      setState(() {
        _image = imageFile;
        captured = true;
        _latitude = lat;
        _longitude = lng;
        _capturedTime = formattedTime;
        _sealDataJson = sealDataJson;
      });
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  /// Haversine formula — returns distance in metres between two coordinates.
  /// Formula: a = sin²(Δφ/2) + cos(φ1)·cos(φ2)·sin²(Δλ/2)
  ///          c = 2·atan2(√a, √(1−a))
  ///          d = R·c   (R = 6371 km)
  double _haversineDistanceMetres(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000; // Earth radius in metres
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  /// Shows "Location doesn't match" popup when distance > 100m
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

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = inspectionFor(widget.inspectionId);

    return Shell(
      role: AppRole.inspector,
      title: 'Seal evidence',
      nav: false,
      backgroundColor: AppColors.scanBg,
      child: Container(
        color: AppColors.scanBg,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Text(
                  'SEAL EVIDENCE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
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
            const SizedBox(height: 24),

            // Camera Box (260x260)
            SizedBox(
              height: 260,
              width: 260,
              child: Stack(
                children: [
                  // Gradient container ki jagah Live Camera Preview ya Captured Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: captured && _image != null
                          ? Image.file(
                              _image!,
                              fit: BoxFit.cover,
                              width: 260,
                              height: 260,
                            )
                          : (_isCameraInitialized && _cameraController != null)
                          ? AspectRatio(
                              aspectRatio: 1,
                              child: CameraPreview(_cameraController!),
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.saffron,
                              ),
                            ),
                    ),
                  ),

                  // Serial Number Overlay
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Colors.black.withValues(alpha: 0.45),
                      child: Text(
                        item.serial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  // Location & Timestamp Overlay
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _latitude != null && _longitude != null
                              ? '${_latitude!.toStringAsFixed(4)}°, ${_longitude!.toStringAsFixed(4)}°'
                              : '23.2599° N',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _capturedTime ?? '11:18:42 AM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              captured
                  ? 'Review seal photo'
                  : 'Position physical seal in frame',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const Spacer(),

            // Actions
            if (captured)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 56,
                            width: 56,
                            child: _image != null
                                ? Image.file(_image!, fit: BoxFit.cover)
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
                                    : 'Timestamped · 11:18:42 AM',
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
                    const SizedBox(height: 16),
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
                            onPressed: () => setState(() {
                              captured = false;
                              _image = null;
                              _latitude = null;
                              _longitude = null;
                              _capturedTime = null;
                              _sealDataJson = null;
                            }),
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
                            onPressed: () async {
                              // --- Haversine distance check ---
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
                                debugPrint(
                                  'Haversine distance: ${distanceM.toStringAsFixed(1)}m',
                                );
                                if (distanceM > 100) {
                                  _showLocationMismatchPopup(distanceM);
                                  return; // block submission
                                }
                              }
                              // --- Distance OK, proceed ---
                              if (ConnectivityService().isOnline.value) {
                                // Online: Emit to socket
                                if (_sealDataJson != null) {
                                  SocketService().emitInspectionApproved(
                                    _sealDataJson!,
                                  );
                                }
                              } else {
                                // Offline: Save to SharedPreferences for later sync
                                if (_sealDataJson != null) {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final pending =
                                      prefs.getStringList(
                                        'pending_inspections',
                                      ) ??
                                      [];
                                  final itemForBusiness = inspectionFor(
                                    widget.inspectionId,
                                  );
                                  final wrapper = {
                                    'inspectionId': widget.inspectionId,
                                    'business': itemForBusiness.business,
                                    'payload': _sealDataJson,
                                  };
                                  pending.add(jsonEncode(wrapper));
                                  await prefs.setStringList(
                                    'pending_inspections',
                                    pending,
                                  );
                                  debugPrint(
                                    'Saved inspection locally for offline sync',
                                  );
                                }
                              }

                              markInspectionDone(widget.inspectionId);
                              if (!context.mounted) return;
                              await showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (_) => _SealSubmittedSheet(
                                  inspectionId: widget.inspectionId,
                                  isOffline:
                                      !ConnectivityService().isOnline.value,
                                ),
                              );
                              if (!context.mounted) return;
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                            child: const Text(
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
                  ],
                ),
              )
            else
              Center(
                child: InkWell(
                  onTap: _takePhoto,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 64,
                    width: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.saffron,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
              color: AppColors.green50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
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
                ? 'Seal evidence saved locally. Please sync when online.'
                : 'Seal evidence geo-tagged and submitted successfully.',
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
