import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class QualityMetricDetail {
  final String metric;
  final double value;
  final double? threshold;
  final bool passed;
  final String? message;

  QualityMetricDetail({
    required this.metric,
    required this.value,
    this.threshold,
    required this.passed,
    this.message,
  });

  factory QualityMetricDetail.fromJson(Map<String, dynamic> json) {
    return QualityMetricDetail(
      metric: json['metric'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble(),
      passed: json['passed'] ?? false,
      message: json['message'] as String?,
    );
  }
}

class SealScanQualityResponse {
  final bool success;
  final bool qualityPassed; // is_acceptable / quality_passed
  final String message;
  final Map<String, dynamic>? metrics;
  final List<QualityMetricDetail> failedMetrics;

  SealScanQualityResponse({
    required this.success,
    required this.qualityPassed,
    required this.message,
    this.metrics,
    this.failedMetrics = const [],
  });

  factory SealScanQualityResponse.fromJson(Map<String, dynamic> json) {
    final bool hasMetrics = json['metrics'] != null;
    final bool successField = json['success'] == true;
    final bool qualityPassedField = json['quality_passed'] == true || json['is_acceptable'] == true;
    final bool passed = hasMetrics && (successField || qualityPassedField);

    final List<QualityMetricDetail> failed = [];
    final List<String> failedMessages = [];

    if (json['failed_metrics'] is List) {
      for (final item in json['failed_metrics']) {
        if (item is Map<String, dynamic>) {
          final detail = QualityMetricDetail.fromJson(item);
          failed.add(detail);
          if (detail.message != null && detail.message!.isNotEmpty) {
            failedMessages.add(detail.message!);
          } else if (detail.metric.isNotEmpty) {
            failedMessages.add('${detail.metric} failed quality threshold');
          }
        } else if (item != null && item.toString().isNotEmpty) {
          failedMessages.add(item.toString());
        }
      }
    }

    String msg = json['message'] ?? '';
    if (msg.isEmpty) {
      if (passed) {
        msg = 'Seal image quality passed all thresholds';
      } else if (failedMessages.isNotEmpty) {
        msg = failedMessages.join('\n• ');
        if (failedMessages.length > 1) {
          msg = '• $msg';
        }
      } else {
        msg = 'Seal image quality check failed. Please capture a clearer image.';
      }
    }

    return SealScanQualityResponse(
      success: successField,
      qualityPassed: passed,
      message: msg,
      metrics: json['metrics'] is Map<String, dynamic> ? json['metrics'] : null,
      failedMetrics: failed,
    );
  }
}
class SealScanApiService {
  static String get _endpointUrl => '${EnvConfig.sealValidationApiUrl}/quality-check';

  /// Step 1 Specification: Static method returning `Map<String, dynamic>?`
  static Future<Map<String, dynamic>?> checkSealQuality(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(_endpointUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': base64String}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error calling SealScan AI Quality Check API: $e');
      return null;
    }
  }

  /// Instance method wrapper for structured response
  Future<SealScanQualityResponse> checkQuality(File imageFile) async {
    final res = await checkSealQuality(imageFile);
    if (res != null) {
      return SealScanQualityResponse.fromJson(res);
    }
    return SealScanQualityResponse(
      success: false,
      qualityPassed: false,
      message: 'Failed to connect to AI Quality Check API. Please try again.',
    );
  }

  /// POST /seal-scan/similarity API call
  static Future<Map<String, dynamic>?> checkSealSimilarity({
    required File currentImageFile,
    required List<String> referenceImageUrls,
  }) async {
    try {
      // 1. Convert current image file to Base64 string
      final bytes = await currentImageFile.readAsBytes();
      final currentBase64 = base64Encode(bytes);

      // 2. Download reference images from HTTP URLs and convert each to Base64 string
      final List<String> referenceBase64List = [];
      for (final url in referenceImageUrls) {
        try {
          if (url.trim().isEmpty) continue;
          final res = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 10));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            referenceBase64List.add(base64Encode(res.bodyBytes));
          }
        } catch (err) {
          debugPrint(
            '[SealSimilarity] Could not fetch reference image from $url: $err',
          );
        }
      }

      final payload = {
        'current_image': currentBase64,
        'reference_images': referenceBase64List,
      };

      final String similarityUrl =
          '${EnvConfig.sealValidationApiUrl}/seal-scan/similarity';
      debugPrint(
        '[SealSimilarity] Sending POST $similarityUrl (${referenceBase64List.length} reference images)...',
      );

      final response = await http
          .post(
            Uri.parse(similarityUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final resMap = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('====================================================');
        debugPrint('[SEAL SCAN SIMILARITY RESPONSE RECEIVED]:');
        debugPrint(const JsonEncoder.withIndent('  ').convert(resMap));
        debugPrint('====================================================');
        return resMap;
      } else {
        debugPrint(
          '[SealSimilarity Error] HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint(
        '[SealSimilarity Exception] Error calling similarity check API: $e',
      );
      return null;
    }
  }
}
