import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SharedPrefsHelper {
  static final SharedPrefsHelper _instance = SharedPrefsHelper._internal();
  factory SharedPrefsHelper() => _instance;
  SharedPrefsHelper._internal();

  static const String _inspectionsKey = 'emaap_inspections_data';
  static const _uuid = Uuid();

  // ─── Core CRUD ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllInspections() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_inspectionsKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveInspections(List<Map<String, dynamic>> inspections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inspectionsKey, jsonEncode(inspections));
  }

  Future<void> insertInspection(Map<String, dynamic> inspection) async {
    final all = await getAllInspections();
    all.removeWhere((e) => e['inspection_id'] == inspection['inspection_id']);
    all.add(inspection);
    await saveInspections(all);
  }

  Future<Map<String, dynamic>?> getInspectionById(String id) async {
    final all = await getAllInspections();
    try {
      return all.firstWhere((e) => e['inspection_id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateInspection(String id, Map<String, dynamic> updates) async {
    final all = await getAllInspections();
    final idx = all.indexWhere((e) => e['inspection_id'] == id);
    if (idx != -1) {
      all[idx] = {...all[idx], ...updates};
      await saveInspections(all);
    }
  }

  // ─── History ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRecentInspections() async {
    final all = await getAllInspections();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final filtered = all.where((e) {
      if (e['status'] == 'PENDING') return false;
      final completed = DateTime.tryParse(e['completed_at'] ?? '');
      return completed != null && completed.isAfter(thirtyDaysAgo);
    }).toList();

    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['completed_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['completed_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return filtered;
  }

  // ─── Pending Queue (with Sticky Re-inspection routing) ───────────────────────

  Future<List<Map<String, dynamic>>> getPendingQueueForLmo(String lmoId) async {
    final all = await getAllInspections();
    final queue = all.where((e) {
      final isNormalPending = e['assignee_id'] == lmoId && e['status'] == 'PENDING';
      final isStickyReinspection =
          e['original_inspector_id'] == lmoId &&
          e['reinspection_status'] == 'PENDING_REINSPECTION';
      return isNormalPending || isStickyReinspection;
    }).toList();

    queue.sort((a, b) {
      // Sort by priority_score DESC, then rectification_deadline ASC
      final pA = (a['priority_score'] as int?) ?? 0;
      final pB = (b['priority_score'] as int?) ?? 0;
      if (pB != pA) return pB.compareTo(pA);
      final dA = DateTime.tryParse(a['rectification_deadline'] ?? '') ?? DateTime(9999);
      final dB = DateTime.tryParse(b['rectification_deadline'] ?? '') ?? DateTime(9999);
      return dA.compareTo(dB);
    });

    return queue;
  }

  // ─── Schedule X Rejection ────────────────────────────────────────────────────

  /// Called when an inspection fails (Checklist OR MPE breach).
  /// Generates a Schedule X notice and sets the 7-day deadline.
  Future<void> issueScheduleXRejection({
    required String inspectionId,
    required List<String> defectReasons,
    required String lmoId,
    String? remarks,
  }) async {
    final now = DateTime.now();
    final deadline = now.add(const Duration(days: 7));

    await updateInspection(inspectionId, {
      'status': 'REJECTED_SCHEDULE_X',
      'rejection_notice_id': 'SCH-X-${_uuid.v4().substring(0, 8).toUpperCase()}',
      'defect_reasons_json': jsonEncode(defectReasons),
      'rejection_timestamp': now.toIso8601String(),
      'rectification_deadline': deadline.toIso8601String(),
      'original_inspector_id': lmoId,
      'reinspection_status': 'NOT_APPLIED',
      'is_reinspection': 0,
      'completed_at': now.toIso8601String(),
      'remarks': remarks ?? 'Rejected under Schedule X',
    });
  }

  // ─── Merchant Re-inspection Application ──────────────────────────────────────

  /// Merchant applies for re-inspection within the 7-day window.
  /// Returns false if deadline has passed.
  Future<bool> applyForReinspection(String inspectionId) async {
    final inspection = await getInspectionById(inspectionId);
    if (inspection == null) return false;

    final deadline = DateTime.tryParse(inspection['rectification_deadline'] ?? '');
    if (deadline == null || DateTime.now().isAfter(deadline)) return false;

    await updateInspection(inspectionId, {
      'reinspection_status': 'PENDING_REINSPECTION',
      'is_reinspection': 1,
      'priority_score': ((inspection['priority_score'] as int?) ?? 0) + 40,
      'status': 'PENDING', // Back to pending for re-inspection
    });
    return true;
  }

  // ─── Mark Re-inspection Resolved ─────────────────────────────────────────────

  Future<void> markReinspectionResolved(String inspectionId) async {
    await updateInspection(inspectionId, {
      'reinspection_status': 'RESOLVED',
      'status': 'VERIFIED',
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── 7-Day SLA Expiry Enforcement ────────────────────────────────────────────

  /// Run on app launch to enforce SLA expiries.
  /// Marks any overdue REJECTED_SCHEDULE_X inspections as EXPIRED_UNVERIFIED.
  Future<int> checkAndEnforceExpiries() async {
    final all = await getAllInspections();
    final now = DateTime.now();
    int expiredCount = 0;

    for (int i = 0; i < all.length; i++) {
      final e = all[i];
      if (e['status'] == 'REJECTED_SCHEDULE_X' &&
          e['reinspection_status'] != 'RESOLVED') {
        final deadline = DateTime.tryParse(e['rectification_deadline'] ?? '');
        if (deadline != null && now.isAfter(deadline)) {
          all[i] = {
            ...e,
            'status': 'EXPIRED_UNVERIFIED',
            'reinspection_status': 'EXPIRED',
          };
          expiredCount++;
        }
      }
    }

    if (expiredCount > 0) await saveInspections(all);
    return expiredCount;
  }
}
