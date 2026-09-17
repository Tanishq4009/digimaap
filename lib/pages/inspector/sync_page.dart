import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../services/socket_service.dart';
import '../../services/connectivity_service.dart';

class InspectorSyncPage extends StatefulWidget {
  const InspectorSyncPage({super.key});

  @override
  State<InspectorSyncPage> createState() => _InspectorSyncPageState();
}

class _InspectorSyncPageState extends State<InspectorSyncPage> {
  List<Map<String, dynamic>> pendingInspections = [];
  int? selectedIndex;
  bool isLoading = true;
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingStrings = prefs.getStringList('pending_inspections') ?? [];
    setState(() {
      pendingInspections = pendingStrings
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
      isLoading = false;
      selectedIndex = null;
    });
  }

  Future<void> _syncSelected() async {
    if (selectedIndex == null) return;
    if (!ConnectivityService().isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot sync while offline!')),
      );
      return;
    }

    setState(() => isSyncing = true);

    try {
      final itemWrapper = pendingInspections[selectedIndex!];
      final itemToSync = itemWrapper.containsKey('payload')
          ? itemWrapper['payload'] as Map<String, dynamic>
          : itemWrapper;

      // Emit via socket
      SocketService().emitInspectionApproved(itemToSync);

      // Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final pendingStrings = prefs.getStringList('pending_inspections') ?? [];
      if (selectedIndex! < pendingStrings.length) {
        pendingStrings.removeAt(selectedIndex!);
        await prefs.setStringList('pending_inspections', pendingStrings);
      }

      await _loadPending();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Synced successfully!')));
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      if (mounted) {
        setState(() => isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.inspector,
      title: 'Offline sync',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync_rounded, color: AppColors.amber),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sync Queue',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Data is safely stored on this device.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select an inspection to sync manually when connection is restored.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (pendingInspections.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text(
                  'No pending inspections to sync.',
                  style: TextStyle(color: AppColors.slate),
                ),
              )
            else ...[
              for (int i = 0; i < pendingInspections.length; i++) ...[
                GestureDetector(
                  onTap: () => setState(() => selectedIndex = i),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedIndex == i
                          ? AppColors.green50
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: selectedIndex == i
                          ? Border.all(color: AppColors.success, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedIndex == i
                                ? Colors.white
                                : AppColors.amber50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedIndex == i
                                ? Icons.check_circle_rounded
                                : Icons.wifi_off_rounded,
                            color: selectedIndex == i
                                ? AppColors.success
                                : AppColors.amber,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pendingInspections[i].containsKey('business')
                                    ? '${pendingInspections[i]['business']}'
                                    : '${pendingInspections[i]['instrumentCategory']} (${pendingInspections[i]['instrumentSerialNumber']})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pendingInspections[i].containsKey(
                                      'inspectionId',
                                    )
                                    ? '${pendingInspections[i]['inspectionId']} · Queued'
                                    : 'Queued',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              PrimaryButton(
                onPressed: selectedIndex != null && !isSyncing
                    ? _syncSelected
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSyncing)
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.sync_rounded),
                    const SizedBox(width: 8),
                    Text(isSyncing ? 'Syncing...' : 'Sync selected'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
