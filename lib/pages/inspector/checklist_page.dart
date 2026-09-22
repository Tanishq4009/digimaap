import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import 'mpe_calculator_page.dart';
import 'defect_capture_page.dart';

class ChecklistPage extends StatefulWidget {
  final String inspectionId;
  const ChecklistPage({
    super.key,
    required this.inspectionId,
  });

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  static const fields = [
    'Display and zero setting',
    'Accuracy at standard load',
    'Physical seal condition',
    'Calibration certificate available',
    'Power and battery condition',
    'Unit markings visible',
    'Tamper indicators intact',
  ];

  final Map<int, String> values = {0: 'PASS', 1: 'PASS', 2: 'PASS', 3: 'PASS'};
  final Map<int, TextEditingController> defectRemarks = {};

  @override
  void dispose() {
    for (var controller in defectRemarks.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = inspectionFor(widget.inspectionId);
    final failed = values.values.contains('FAIL');

    return Shell(
      role: AppRole.inspector,
      title: 'Inspection checklist',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.business,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${values.length} / 7 checked',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: values.length / 7,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.saffron,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < fields.length; i++) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: values[i] == 'FAIL' ? AppColors.red50 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: values[i] == 'FAIL'
                        ? AppColors.red200
                        : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fields[i],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['PASS', 'FAIL', 'N/A'].map((status) {
                        final active = values[i] == status;
                        final Color bg = active
                            ? (status == 'FAIL'
                                  ? AppColors.errorRed
                                  : AppColors.navy)
                            : AppColors.slate100;
                        final Color fg = active
                            ? Colors.white
                            : AppColors.slate;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Material(
                              color: bg,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    values[i] = status;
                                    if (status != 'FAIL') {
                                      defectRemarks[i]?.dispose();
                                      defectRemarks.remove(i);
                                    } else {
                                      defectRemarks[i] =
                                          TextEditingController();
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    status,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: fg,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (values[i] == 'FAIL') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Specific Remarks',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.errorRed,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: defectRemarks[i],
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe the issue...',
                          hintStyle: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.red200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.errorRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              onPressed: () {
                if (failed) {
                  // Collect failed fields
                  final failedFields = values.entries
                      .where((e) => e.value == 'FAIL')
                      .map((e) => fields[e.key])
                      .toList();

                  // Navigate to Defect Capture Module
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DefectCapturePage(
                        inspectionId: widget.inspectionId,
                        failedFields: failedFields,
                      ),
                    ),
                  );
                } else {
                  // Normal MPE flow
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MpeCalculatorPage(
                        inspectionId: widget.inspectionId,
                      ),
                    ),
                  );
                }
              },
              // For failures we change button text to make it obvious
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    failed
                        ? 'Log Defect & Capture Evidence'
                        : 'Continue to MPE Check',
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    failed ? Icons.warning_amber_rounded : Icons.arrow_forward,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
