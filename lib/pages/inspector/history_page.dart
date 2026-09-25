import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/local/shared_prefs_helper.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';

class InspectorHistoryPage extends StatefulWidget {
  const InspectorHistoryPage({super.key});

  @override
  State<InspectorHistoryPage> createState() =>
      _InspectorHistoryPageState();
}

class _InspectorHistoryPageState
    extends State<InspectorHistoryPage> {
  final SharedPrefsHelper _prefsHelper =
      SharedPrefsHelper();
  final TextEditingController _searchController =
      TextEditingController();
  List<Map<String, dynamic>> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentInspections();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _loadRecentInspections() async {
    setState(() {
      _isLoading = true;
    });
    final inspections = await _prefsHelper
        .getRecentInspections();
    setState(() {
      _inspections = inspections;
      _isLoading = false;
    });
  }

  void _showInspectionDetails(
    Map<String, dynamic> inspection,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isVerified =
            inspection['status'] == 'VERIFIED';
        final checklist =
            jsonDecode(
                  inspection['visual_checklist_json'] ??
                      '{}',
                )
                as Map<String, dynamic>;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(
              context,
            ).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(
                        bottom: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate200,
                        borderRadius: BorderRadius.circular(
                          2,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              inspection['merchant_name'] ??
                                  'Unknown Merchant',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              inspection['inspection_id'] ??
                                  '',
                              style: const TextStyle(
                                color: AppColors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? AppColors.green50
                              : AppColors.red50,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: isVerified
                                ? AppColors.green100
                                : AppColors.red100,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: isVerified
                                  ? AppColors.success
                                  : AppColors.errorRed,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isVerified
                                  ? 'VERIFIED'
                                  : 'REJECTED',
                              style: TextStyle(
                                color: isVerified
                                    ? AppColors.success
                                    : AppColors.errorRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Instrument Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Category',
                    inspection['instrument_category'] ??
                        'N/A',
                  ),
                  _buildDetailRow(
                    'Serial No',
                    inspection['serial_number'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Class',
                    inspection['accuracy_class'] ?? 'N/A',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Metrological Performance',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Observed Error',
                    '${inspection['mpe_error_margin']}%',
                  ),
                  _buildDetailRow(
                    'Allowed MPE',
                    '${inspection['mpe_threshold']}%',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Visual Checklist',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...checklist.entries.map(
                    (e) => _buildDetailRow(
                      e.key,
                      e.value.toString(),
                    ),
                  ),
                  if (!isVerified) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Rejection Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorRed,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Defect Category',
                      inspection['defect_category'] ??
                          'N/A',
                    ),
                    _buildDetailRow(
                      'Remarks',
                      inspection['remarks'] ?? 'N/A',
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: inspectedInspectionIds,
      builder: (context, doneIds, child) {
        _prefsHelper.getRecentInspections().then((data) {
          if (mounted && data.length != _inspections.length) {
            setState(() {
              _inspections = data;
              _isLoading = false;
            });
          }
        });

        final query = _searchController.text.toLowerCase();
        final shown = _inspections.where((e) {
          final merchant = (e['merchant_name'] ?? '').toLowerCase();
          final serial = (e['serial_number'] ?? '').toLowerCase();
          return merchant.contains(query) || serial.contains(query);
        }).toList();

        return Shell(
          role: AppRole.inspector,
          title: 'Inspection History',
          child: Column(
            children: [
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search merchant or serial...',
                hintStyle: const TextStyle(
                  color: AppColors.slate400,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.slate,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : shown.isEmpty
                ? const Center(
                    child: Text(
                      'No history found.',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: 100,
                    ), // extra padding for bottom nav
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final inspection = shown[index];
                      final isVerified =
                          inspection['status'] ==
                          'VERIFIED';

                      return InkWell(
                        onTap: () => _showInspectionDetails(
                          inspection,
                        ),
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.slate200,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? AppColors.green50
                                      : AppColors.red50,
                                  borderRadius:
                                      BorderRadius.circular(
                                        12,
                                      ),
                                ),
                                child: Icon(
                                  isVerified
                                      ? Icons
                                            .verified_rounded
                                      : Icons
                                            .cancel_outlined,
                                  color: isVerified
                                      ? AppColors.success
                                      : AppColors.errorRed,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      inspection['merchant_name'] ??
                                          'Unknown',
                                      style:
                                          const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            fontSize: 15,
                                            color: AppColors
                                                .ink,
                                          ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      '${inspection['instrument_category']} · ${inspection['status']}',
                                      style:
                                          const TextStyle(
                                            fontSize: 13,
                                            color: AppColors
                                                .slate,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.slate400,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
      },
    );
  }
}
