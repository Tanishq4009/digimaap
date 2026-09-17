class VerificationForm {
  final String instrumentCategory;
  final String instrumentSubCategory;
  final String modelNo;
  final String accuracyClass; 
  final String manufacturerName;
  final String instrumentSerialNumber;
  final String metric;
  final String address;
  final int pincode;
  final String state;
  final double lat;
  final double long;

  VerificationForm({
    required this.instrumentCategory,
    required this.instrumentSubCategory,
    required this.modelNo,
    required this.accuracyClass,
    required this.manufacturerName,
    required this.instrumentSerialNumber,
    required this.metric,
    required this.address,
    required this.pincode,
    required this.state,
    required this.lat,
    required this.long,
  });

  factory VerificationForm.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerificationForm(
      instrumentCategory: json['instrumentCategory'] ?? '',
      instrumentSubCategory:
          json['instrumentSubCategory'] ?? '',
      modelNo: json['modelNo'] ?? '',
      accuracyClass: json['accuracyClass'] ?? 'Class III',
      manufacturerName: json['manufacturerName'] ?? '',
      instrumentSerialNumber:
          json['instrumentSerialNumber'] ??
          '', 
      metric: json['metric'] ?? '',
      address: json['address'] ?? '',
      pincode: json['pincode'] is int
          ? json['pincode']
          : int.tryParse(json['pincode'].toString()) ?? 0,
      state: json['state'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      long: (json['long'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instrumentCategory': instrumentCategory,
      'instrumentSubCategory': instrumentSubCategory,
      'modelNo': modelNo,
      'accuracyClass': accuracyClass,
      'manufacturerName': manufacturerName,
      'instrumentSerialNumber': instrumentSerialNumber,
      'metric': metric,
      'address': address,
      'pincode': pincode,
      'state': state,
      'lat': lat,
      'long': long,
    };
  }
}
