import 'dart:convert';

class SealEvidence {
  final String instrumentSerialNumber;
  final String instrumentCategory;
  final double lat;
  final double long;
  final String sealImageBase64;
  final List<String> sealImageUrls;
  final String tokenHash;
  final String status;
  final int timeStamp;
  final String? applicationId;
  final String? inspectorId;

  const SealEvidence({
    required this.instrumentSerialNumber,
    this.instrumentCategory = '',
    required this.lat,
    required this.long,
    this.sealImageBase64 = '',
    this.sealImageUrls = const [],
    this.tokenHash = '',
    this.status = 'APPROVED_CHECKLIST',
    this.timeStamp = 0,
    this.applicationId,
    this.inspectorId,
  });

  Map<String, dynamic> toJson() {
    return {
      'instrumentSerialNumber': instrumentSerialNumber,
      'instrumentCategory': instrumentCategory,
      'lat': lat,
      'long': long,
      'sealImageBase64': sealImageBase64,
      'sealImageUrls': sealImageUrls,
      'token_hash': tokenHash,
      'status': status,
      'timeStamp': timeStamp,
      if (applicationId != null) 'applicationId': applicationId,
      if (inspectorId != null) 'inspectorId': inspectorId,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory SealEvidence.fromJson(Map<String, dynamic> json) {
    return SealEvidence(
      instrumentSerialNumber: json['instrumentSerialNumber'] as String? ?? '',
      instrumentCategory: json['instrumentCategory'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      long: (json['long'] as num?)?.toDouble() ?? 0.0,
      sealImageBase64: json['sealImageBase64'] as String? ?? '',
      sealImageUrls: (json['sealImageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tokenHash: json['token_hash'] as String? ?? '',
      status: json['status'] as String? ?? 'APPROVED_CHECKLIST',
      timeStamp: (json['timeStamp'] as num?)?.toInt() ?? 0,
      applicationId: json['applicationId'] as String?,
      inspectorId: json['inspectorId'] as String?,
    );
  }
}
