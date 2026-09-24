import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static final SharedPrefsHelper _instance = SharedPrefsHelper._internal();
  factory SharedPrefsHelper() => _instance;
  SharedPrefsHelper._internal();

  static const String _inspectionsKey = 'emaap_inspections_data';

  Future<List<Map<String, dynamic>>> getAllInspections() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_inspectionsKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveInspections(List<Map<String, dynamic>> inspections) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(inspections);
    await prefs.setString(_inspectionsKey, jsonString);
  }

  Future<void> insertInspection(Map<String, dynamic> inspection) async {
    final inspections = await getAllInspections();
    inspections.removeWhere((e) => e['inspection_id'] == inspection['inspection_id']);
    inspections.add(inspection);
    await saveInspections(inspections);
  }

  Future<List<Map<String, dynamic>>> getRecentInspections() async {
    final all = await getAllInspections();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    final filtered = all.where((e) {
      if (e['status'] == 'PENDING') return false;
      if (e['completed_at'] != null) {
        final completed = DateTime.tryParse(e['completed_at']);
        if (completed != null && completed.isAfter(thirtyDaysAgo)) return true;
      }
      return false;
    }).toList();
    
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['completed_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['completed_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });
    
    return filtered;
  }
}
