import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/local/shared_prefs_helper.dart';
import 'seal_evidence.dart';

export 'seal_evidence.dart';

/// Data models ported from client/components/emapp/index.tsx

class CertificateData {
  final String id;
  final String number;
  final String instrument;
  final String category;
  final String authority;
  final String status; // 'valid' | 'expired' | 'invalid'
  final String issueDate;
  final String expiryDate;
  final String merchantName;
  final String address;
  final String serial;
  final String accuracyClass;
  final String capacity;
  final String scaleInterval;
  final String inspectorName;
  final String inspectorId;

  const CertificateData({
    required this.id,
    required this.number,
    required this.instrument,
    required this.category,
    required this.authority,
    required this.status,
    required this.issueDate,
    required this.expiryDate,
    required this.merchantName,
    required this.address,
    required this.serial,
    required this.accuracyClass,
    required this.capacity,
    required this.scaleInterval,
    required this.inspectorName,
    required this.inspectorId,
  });
}

final Map<String, CertificateData> certificates = {
  'LM-DL-2026-00452': const CertificateData(
    id: 'LM-DL-2026-00452',
    number: 'LM/DL/2026/00452',
    instrument: 'Electronic Weighing Scale',
    category: 'Commercial Weighing Instrument',
    authority: 'Legal Metrology, Madhya Pradesh',
    status: 'valid',
    issueDate: '08 Jan 2026',
    expiryDate: '07 Jan 2027',
    merchantName: 'Sharma Fuel & Weighing Services',
    address: 'Ayodhya Bypass Road, Bhopal, MP',
    serial: 'ES-24-MP-8831',
    accuracyClass: 'Class III',
    capacity: '30 kg',
    scaleInterval: '5 g',
    inspectorName: 'Anil Kumar',
    inspectorId: 'LMO-MP-1048',
  ),
  'LM-MP-2025-01871': const CertificateData(
    id: 'LM-MP-2025-01871',
    number: 'LM/MP/2025/01871',
    instrument: 'Retail Platform Scale',
    category: 'Retail Weighing Instrument',
    authority: 'Legal Metrology, Madhya Pradesh',
    status: 'valid',
    issueDate: '11 Feb 2025',
    expiryDate: '10 Feb 2026',
    merchantName: 'Bharat Weighing House',
    address: 'Govindpura Industrial Area, MP',
    serial: 'AV-24-MP-1192',
    accuracyClass: 'Class III',
    capacity: '100 kg',
    scaleInterval: '10 g',
    inspectorName: 'Rahul Singh',
    inspectorId: 'LMO-MP-1049',
  ),
  'LM-DL-2024-09314': const CertificateData(
    id: 'LM-DL-2024-09314',
    number: 'LM/DL/2024/09314',
    instrument: 'Fuel Dispenser',
    category: 'Fuel Dispensing Instrument',
    authority: 'Legal Metrology, Delhi',
    status: 'expired',
    issueDate: '18 Dec 2024',
    expiryDate: '17 Dec 2025',
    merchantName: 'Delhi Petrol Pump',
    address: 'CP, New Delhi',
    serial: 'DL-FD-9921',
    accuracyClass: 'Class 0.5',
    capacity: 'N/A',
    scaleInterval: '0.01 L',
    inspectorName: 'Amit Desai',
    inspectorId: 'LMO-DL-2021',
  ),
};

final CertificateData certificate =
    certificates['LM-DL-2026-00452']!;

class InspectionData {
  final String id;
  final String business;
  final String address;
  final String applicant;
  final String instrument;
  final String model;
  final String serial;
  final String time;
  final String distance;
  final String priority;
  final bool isLive; 
  final String? accuracyClass;
  final String? applicationId;
  final String? assignedOfficerId;
  final String? assignedType;
  final String? assignedTo;
  final String? previousCertificateUrl;
  final String? manufacturerCertificateUrl;
  final double? error;

  const InspectionData({
    required this.id,
    required this.business,
    required this.address,
    required this.applicant,
    required this.instrument,
    required this.model,
    required this.serial,
    required this.time,
    required this.distance,
    required this.priority,
    this.isLive = false, 
    this.accuracyClass,
    this.applicationId,
    this.assignedOfficerId,
    this.assignedType,
    this.assignedTo,
    this.previousCertificateUrl,
    this.manufacturerCertificateUrl,
    this.error,
  });
}

final Map<String, InspectionData> inspections = {
  'LM-260112-04': const InspectionData(
    id: 'LM-260112-04',
    business: 'Sharma Fuel & Weighing Services',
    address: 'Ayodhya Bypass Road, Bhopal',
    applicant: 'Amit Sharma',
    instrument: 'Electronic weighing scale',
    model: 'Essae · JEW-300',
    serial: 'ES-24-MP-8831',
    time: '11:00 AM',
    distance: '2.8 km',
    priority: 'HIGH PRIORITY',
  ),
};

InspectionData inspectionFor(String? id) =>
    inspections[id] ?? inspections['LM-260112-04']!;

final Map<String, Map<String, double>> _inspectionLocations = {};

/// Store expected lat/long for a given inspection id
void storeInspectionLocation(String id, double lat, double lng) {
  _inspectionLocations[id] = {'lat': lat, 'lng': lng};
}

/// Retrieve stored expected location for an inspection id
Map<String, double>? getInspectionLocation(String id) {
  return _inspectionLocations[id];
}

final ValueNotifier<List<String>> liveInspectionIds = ValueNotifier<List<String>>([]);

/// IDs of inspections that have been VERIFIED (sealed) — removed from home
final ValueNotifier<List<String>> inspectedInspectionIds =
    ValueNotifier<List<String>>([]);

/// IDs of inspections that are REJECTED (Schedule X) — stay on home with deadline
final ValueNotifier<List<String>> rejectedInspectionIds =
    ValueNotifier<List<String>>([]);

/// Call this when an inspection is VERIFIED — removes it from home queue & saves to history
void markInspectionDone(String id) {
  if (!inspectedInspectionIds.value.contains(id)) {
    inspectedInspectionIds.value = [id, ...inspectedInspectionIds.value];
  }
  final item = inspectionFor(id);
  SharedPrefsHelper().insertInspection({
    'inspection_id': id,
    'merchant_name': item.business,
    'shop_address': item.address,
    'instrument_category': item.instrument,
    'serial_number': item.serial,
    'accuracy_class': item.accuracyClass ?? 'Class III',
    'status': 'VERIFIED',
    'completed_at': DateTime.now().toIso8601String(),
    'mpe_error_margin': item.error ?? 0.0,
    'mpe_threshold': item.error ?? 0.5,
    'certificate_pdf_path': '/storage/certificates/$id.pdf',
    'photo_evidence_paths': jsonEncode([]),
  });
}

/// Call this when an inspection is REJECTED — keeps it on home with deadline banner
void markInspectionRejected(String id) {
  if (!rejectedInspectionIds.value.contains(id)) {
    rejectedInspectionIds.value = [id, ...rejectedInspectionIds.value];
  }
}

/// Builds a new InspectionData from a live verification request, registers
/// it in [inspections] and [liveInspectionIds], and returns its id.
String addLiveInspection({
  required String business,
  required String instrument,
  required String model,
  required String serial,
  String address = 'Live verification request',
  String applicant = '—',
  String? accuracyClass,
  String? applicationId,
  String? assignedOfficerId,
  String? assignedType,
  String? assignedTo,
  String? previousCertificateUrl,
  String? manufacturerCertificateUrl,
  double? error,
  String? time,
  String? customId,
}) {
  final id = customId ?? 'LIVE-${DateTime.now().millisecondsSinceEpoch}';
  inspections[id] = InspectionData(
    id: id,
    business: business,
    address: address,
    applicant: applicant,
    instrument: instrument,
    model: model,
    serial: serial,
    time: time ?? 'Just now',
    distance: '—',
    priority: 'NEW REQUEST',
    isLive: true,
    accuracyClass: accuracyClass,
    applicationId: applicationId,
    assignedOfficerId: assignedOfficerId,
    assignedType: assignedType,
    assignedTo: assignedTo,
    previousCertificateUrl: previousCertificateUrl,
    manufacturerCertificateUrl: manufacturerCertificateUrl,
    error: error,
  );
  liveInspectionIds.value = [
    id,
    ...liveInspectionIds.value,
  ];
  return id;
}

/// In-memory storage for seal evidence JSON data
final Map<String, SealEvidence> recordedSealEvidences = {};

void saveSealEvidence(String inspectionId, SealEvidence evidence) {
  recordedSealEvidences[inspectionId] = evidence;
}

SealEvidence? getSealEvidence(String inspectionId) {
  return recordedSealEvidences[inspectionId];
}