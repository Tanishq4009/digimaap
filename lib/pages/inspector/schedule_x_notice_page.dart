import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../data/local/shared_prefs_helper.dart';
import '../../models/data.dart';

class ScheduleXNoticePage extends StatefulWidget {
  final String inspectionId;
  const ScheduleXNoticePage({super.key, required this.inspectionId});

  @override
  State<ScheduleXNoticePage> createState() => _ScheduleXNoticePageState();
}

class _ScheduleXNoticePageState extends State<ScheduleXNoticePage> {
  final SharedPrefsHelper _prefs = SharedPrefsHelper();
  Map<String, dynamic>? _inspection;
  bool _isLoading = true;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _prefs.checkAndEnforceExpiries();
    var data = await _prefs.getInspectionById(widget.inspectionId);
    if (data == null || data['rectification_deadline'] == null) {
      final item = inspectionFor(widget.inspectionId);
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 7));
      data = {
        'inspection_id': widget.inspectionId,
        'rejection_notice_id': 'SCH-X-${widget.inspectionId.replaceAll('-', '')}',
        'merchant_name': item.business,
        'shop_address': item.address,
        'instrument_category': item.instrument,
        'serial_number': item.serial,
        'accuracy_class': item.accuracyClass ?? 'Class III',
        'status': 'REJECTED_SCHEDULE_X',
        'rectification_deadline': deadline.toIso8601String(),
        'rejection_timestamp': now.toIso8601String(),
        'reinspection_status': 'NOT_APPLIED',
        'defect_reasons_json': jsonEncode(['Visual Checklist Defect', 'MPE Error Threshold Breached']),
        'remarks': 'Rejected under Schedule X due to metrological inaccuracy.',
        ...?data,
      };
    }
    setState(() {
      _inspection = data;
      _isLoading = false;
    });
  }

  Future<void> _applyReinspection() async {
    setState(() => _isApplying = true);
    final success = await _prefs.applyForReinspection(widget.inspectionId);
    setState(() => _isApplying = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Re-inspection request submitted. Same LMO will be assigned.'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rectification deadline has passed. Section 33 violation flagged.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_inspection == null) {
      return const Scaffold(body: Center(child: Text('Inspection not found.')));
    }

    final inspection = _inspection!;
    final reinspectionStatus = inspection['reinspection_status'] ?? 'NOT_APPLIED';
    final isExpired = inspection['status'] == 'EXPIRED_UNVERIFIED' || reinspectionStatus == 'EXPIRED';
    final isResolved = reinspectionStatus == 'RESOLVED';
    final isPending = reinspectionStatus == 'PENDING_REINSPECTION';

    final deadline = DateTime.tryParse(inspection['rectification_deadline'] ?? '');
    final deadlineStr = deadline != null
        ? '${deadline.day}/${deadline.month}/${deadline.year}'
        : 'N/A';

    final daysLeft = deadline != null
        ? deadline.difference(DateTime.now()).inDays
        : 0;

    final defects = inspection['defect_reasons_json'] != null
        ? (jsonDecode(inspection['defect_reasons_json']) as List).cast<String>()
        : <String>[];

    return Shell(
      role: AppRole.inspector,
      title: 'Schedule X Notice',
      nav: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // ── Header Banner ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LEGAL METROLOGY ACT',
                    style: TextStyle(
                      color: AppColors.blue100,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Schedule X Rejection Notice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Notice ID: ${inspection['rejection_notice_id'] ?? 'N/A'}',
                    style: const TextStyle(color: AppColors.blue100, fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status Chip ───────────────────────────────────────────
                  _StatusBanner(
                    isExpired: isExpired,
                    isResolved: isResolved,
                    isPending: isPending,
                    daysLeft: daysLeft,
                    deadlineStr: deadlineStr,
                  ),

                  const SizedBox(height: 20),

                  // ── Merchant Details ──────────────────────────────────────
                  _SectionCard(
                    title: 'Merchant & Instrument',
                    children: [
                      _Row('Business', inspection['merchant_name'] ?? 'N/A'),
                      _Row('Address', inspection['shop_address'] ?? 'N/A'),
                      _Row('Category', inspection['instrument_category'] ?? 'N/A'),
                      _Row('Serial No', inspection['serial_number'] ?? 'N/A'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Defect Reasons ────────────────────────────────────────
                  _SectionCard(
                    title: 'Grounds of Rejection',
                    children: defects.isEmpty
                        ? [const Text('No defects recorded.', style: TextStyle(color: AppColors.slate))]
                        : defects
                            .map(
                              (d) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.cancel_outlined, color: AppColors.errorRed, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(d, style: const TextStyle(color: AppColors.ink))),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),

                  const SizedBox(height: 16),

                  // ── Remarks ───────────────────────────────────────────────
                  if (inspection['remarks'] != null)
                    _SectionCard(
                      title: 'Inspector Remarks',
                      children: [
                        Text(
                          inspection['remarks'],
                          style: const TextStyle(color: AppColors.ink, height: 1.5),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // ── 7-Day Deadline Tracker ────────────────────────────────
                  _DeadlineTracker(
                    deadline: deadline,
                    daysLeft: daysLeft,
                    isExpired: isExpired,
                  ),

                  const SizedBox(height: 24),

                  // ── Action Button ─────────────────────────────────────────
                  if (!isExpired && !isResolved && !isPending)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isApplying ? null : _applyReinspection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saffron,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isApplying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Apply for Re-inspection',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                  if (isPending)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.blue100),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.schedule, color: AppColors.navy),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Re-inspection Requested. The same LMO has been notified and will conduct the re-inspection.',
                              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isExpired)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.red50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.red100),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gavel, color: AppColors.errorRed),
                              SizedBox(width: 12),
                              Text(
                                'Section 33 Violation Flagged',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The 7-day rectification window has expired without compliance. This instrument is flagged for enforcement action under Section 33 of the Legal Metrology Act.',
                            style: TextStyle(color: AppColors.errorRed, height: 1.5),
                          ),
                        ],
                      ),
                    ),

                  if (isResolved)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.green50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.green100),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: AppColors.success),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Re-inspection completed. Instrument is now verified.',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool isExpired;
  final bool isResolved;
  final bool isPending;
  final int daysLeft;
  final String deadlineStr;

  const _StatusBanner({
    required this.isExpired,
    required this.isResolved,
    required this.isPending,
    required this.daysLeft,
    required this.deadlineStr,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;
    final IconData icon;
    final String label;

    if (isExpired) {
      bg = AppColors.red50; border = AppColors.red100;
      textColor = AppColors.errorRed;
      icon = Icons.error_outline;
      label = 'EXPIRED — Section 33 Violation';
    } else if (isResolved) {
      bg = AppColors.green50; border = AppColors.green100;
      textColor = AppColors.success;
      icon = Icons.check_circle_outline;
      label = 'RESOLVED — Instrument Verified';
    } else if (isPending) {
      bg = AppColors.blue50; border = AppColors.blue100;
      textColor = AppColors.navy;
      icon = Icons.pending_outlined;
      label = 'RE-INSPECTION PENDING';
    } else {
      bg = AppColors.amber50; border = AppColors.amber200;
      textColor = AppColors.amber;
      icon = Icons.timer_outlined;
      label = '$daysLeft day${daysLeft == 1 ? '' : 's'} left to rectify (Deadline: $deadlineStr)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineTracker extends StatefulWidget {
  final DateTime? deadline;
  final int daysLeft;
  final bool isExpired;

  const _DeadlineTracker({
    required this.deadline,
    required this.daysLeft,
    required this.isExpired,
  });

  @override
  State<_DeadlineTracker> createState() => _DeadlineTrackerState();
}

class _DeadlineTrackerState extends State<_DeadlineTracker> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateRemaining();
        });
      }
    });
  }

  void _updateRemaining() {
    final target = widget.deadline ?? DateTime.now().add(const Duration(days: 7));
    final diff = target.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (widget.deadline == null) return const SizedBox.shrink();

    final isExpired = widget.isExpired || _remaining == Duration.zero;
    final totalSeconds = _remaining.inSeconds;
    final max7DaysSec = 7 * 24 * 3600;
    final progress = isExpired ? 1.0 : (1.0 - (totalSeconds / max7DaysSec)).clamp(0.0, 1.0);

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final barColor = isExpired
        ? AppColors.errorRed
        : days <= 2
            ? AppColors.errorRed
            : days <= 4
                ? AppColors.amber
                : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '7-Day Rectification Window',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isExpired ? AppColors.red50 : AppColors.amber50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isExpired ? 'EXPIRED' : 'ACTIVE TIMER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isExpired ? AppColors.errorRed : AppColors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live Timer Boxes
          if (!isExpired)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: days <= 2 ? AppColors.red50 : AppColors.amber50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: days <= 2 ? AppColors.red200 : AppColors.amber200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _timerBox(_twoDigits(days), 'DAYS', barColor),
                  _timerColon(barColor),
                  _timerBox(_twoDigits(hours), 'HOURS', barColor),
                  _timerColon(barColor),
                  _timerBox(_twoDigits(minutes), 'MINS', barColor),
                  _timerColon(barColor),
                  _timerBox(_twoDigits(seconds), 'SECS', barColor),
                ],
              ),
            ),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.slate100,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpired ? 'Window Closed' : '$days days, ${_twoDigits(hours)}h ${_twoDigits(minutes)}m left',
                style: TextStyle(color: barColor, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                'Deadline: ${widget.deadline!.day}/${widget.deadline!.month}/${widget.deadline!.year}',
                style: const TextStyle(color: AppColors.slate, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerBox(String val, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _timerColon(Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.slate, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
