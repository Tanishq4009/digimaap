import 'dart:convert';
import 'dart:io';

class SealEvidence {
  final String instrumentSerialNumber;
  final double lat;
  final double long;
  final String sealImageBase64;

  const SealEvidence({
    required this.instrumentSerialNumber,
    required this.lat,
    required this.long,
    required this.sealImageBase64,
  });

  /// Returns the exact JSON key-value pairs
  Map<String, dynamic> toJson() {
    return {
      'instrumentSerialNumber': instrumentSerialNumber,
      'lat': lat,
      'long': long,
      'sealImageBase64': sealImageBase64,
    };
  }

  /// Encodes this evidence to a raw JSON string
  String toJsonString() => jsonEncode(toJson());

  factory SealEvidence.fromJson(Map<String, dynamic> json) {
    return SealEvidence(
      instrumentSerialNumber: json['instrumentSerialNumber'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      long: (json['long'] as num?)?.toDouble() ?? 0.0,
      sealImageBase64: json['sealImageBase64'] as String? ?? '',
    );
  }

  /// Creates a SealEvidence instance from a File by base64 encoding its bytes
  static Future<SealEvidence> fromFile({
    required String instrumentSerialNumber,
    required double? lat,
    required double? long,
    required File imageFile,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64String = base64Encode(bytes);
    return SealEvidence(
      instrumentSerialNumber: instrumentSerialNumber,
      lat: lat ?? 0.0,
      long: long ?? 0.0,
      sealImageBase64: base64String,
    );
  }
}
