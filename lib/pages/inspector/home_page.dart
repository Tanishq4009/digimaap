import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../routes.dart';
import 'inspection_detail_page.dart';
import '../../services/connectivity_service.dart';
import '../../data/local/shared_prefs_helper.dart';
import 'schedule_x_notice_page.dart';

class InspectorHomePage extends StatelessWidget {
  const InspectorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Shell(
      role: AppRole.inspector,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monday, 12 January 2026',
                    style: TextStyle(color: AppColors.blue100, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Good morning, Rajesh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Legal Metrology Officer · Bhopal Circle',
                    style: TextStyle(
                      color: AppColors.blue100,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _statCard('04', 'Assigned today', false),
                      const SizedBox(width: 8),
                      _statCard('02', 'Pending sync', true),
                      const SizedBox(width: 8),
                      _statCard('38', 'This month', false),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: ConnectivityService().isOnline,
                    builder: (context, isOnline, child) {
                      if (isOnline) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: InkWell(
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(Routes.inspectorSync),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.amber50,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(80),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  color: AppColors.amber,
                                  size: 19,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Offline mode',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Data will sync when online',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.slate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.amber,
                                  size: 17,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's inspections",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(Routes.inspectorInspections),
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Listen to live + verified + rejected notifiers
                  ValueListenableBuilder<List<String>>(
                    valueListenable: liveInspectionIds,
                    builder: (context, liveIds, _) {
                      return ValueListenableBuilder<List<String>>(
                        valueListenable: inspectedInspectionIds,
                        builder: (context, doneIds, _) {
                          return ValueListenableBuilder<List<String>>(
                            valueListenable: rejectedInspectionIds,
                            builder: (context, rejectedIds, _) {
                              final allIds = {...inspections.keys, ...liveIds}.toList();
                              // Only remove VERIFIED ones — rejected ones STAY
                              final visibleIds = allIds
                                  .where((id) => !doneIds.contains(id))
                                  .toList();

                              if (visibleIds.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.slate200),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, color: AppColors.slate400, size: 36),
                                      SizedBox(height: 8),
                                      Text(
                                        'No inspection requests right now',
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Live requests assigned via socket will appear here.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.slate,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final id in visibleIds) ...[
                                    _InspectionCard(
                                      item: inspectionFor(id),
                                      isRejected: rejectedIds.contains(id),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, bool highlight) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.amber.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: highlight ? const Color(0xFFFDE68A) : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.blue100,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single inspection card, shared by the live and static list.
/// Draws a red outline + red "NEW REQUEST" badge for live items.
/// For REJECTED_SCHEDULE_X items: shows deadline + hides Begin Inspection.
class _InspectionCard extends StatefulWidget {
  final InspectionData item;
  final bool isRejected;
  const _InspectionCard({required this.item, this.isRejected = false});

  @override
  State<_InspectionCard> createState() => _InspectionCardState();
}

class _InspectionCardState extends State<_InspectionCard> {
  final _prefs = SharedPrefsHelper();
  DateTime? _deadline;
  bool _isPendingReinspection = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRejected) _loadRejectionData();
  }

  @override
  void didUpdateWidget(_InspectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRejected && !oldWidget.isRejected) _loadRejectionData();
  }

  Future<void> _loadRejectionData() async {
    final data = await _prefs.getInspectionById(widget.item.id);
    final deadlineStr = data?['rectification_deadline'];
    final parsed = deadlineStr != null ? DateTime.tryParse(deadlineStr) : null;
    if (mounted) {
      setState(() {
        _deadline = parsed ?? DateTime.now().add(const Duration(days: 7));
        _isPendingReinspection = data?['reinspection_status'] == 'PENDING_REINSPECTION';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isRejected = widget.isRejected;
    final isPendingReinspection = _isPendingReinspection;
    final deadline = _deadline;
    final daysLeft = deadline != null ? deadline.difference(DateTime.now()).inDays : 0;

    return InkWell(
      onTap: () {
        if (isRejected) {
          // Block inspection — show rejection notice dialog
          showDialog(
            context: context,
            builder: (ctx) => _RejectionBlockDialog(
              inspectionId: item.id,
              businessName: item.business,
              deadline: deadline,
              onViewNotice: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ScheduleXNoticePage(inspectionId: item.id),
                ));
              },
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InspectionDetailPage(inspectionId: item.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: item.isLive
                  ? AppColors.errorRed.withAlpha(80)
                  : isRejected
                      ? AppColors.errorRed.withAlpha(40)
                      : Colors.black.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: item.isLive
              ? Border.all(color: AppColors.errorRed, width: 1.5)
              : isRejected
                  ? Border.all(color: AppColors.errorRed.withAlpha(100), width: 1)
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.isLive) ...[
                            Container(
                              height: 7,
                              width: 7,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.errorRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              item.business,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.slate,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.address,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.slate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.isLive
                        ? AppColors.red50
                        : isRejected
                            ? AppColors.red50
                            : AppColors.orange50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isRejected ? 'REJECTED' : item.priority,
                    style: TextStyle(
                      color: item.isLive || isRejected
                          ? AppColors.errorRed
                          : AppColors.saffron,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            // ── Rejection Deadline Banner ────────────────────────────────────
            if (isRejected && deadline != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: daysLeft <= 2 ? AppColors.red50 : AppColors.amber50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: daysLeft <= 2 ? AppColors.red200 : AppColors.amber200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: daysLeft <= 2 ? AppColors.errorRed : AppColors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        daysLeft > 0
                            ? '$daysLeft day${daysLeft == 1 ? '' : 's'} left for rectification (Schedule X)'
                            : 'Deadline passed — Section 33 action pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: daysLeft <= 2 ? AppColors.errorRed : AppColors.amber,
                        ),
                      ),
                    ),
                    if (!isPendingReinspection)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ScheduleXNoticePage(inspectionId: item.id),
                          ),
                        ),
                        child: const Text(
                          'View →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.slate100),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
                Text(
                  item.distance,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
                // "Begin Inspection" only if NOT rejected, OR if re-inspection applied
                if (!isRejected || isPendingReinspection)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Begin Inspection',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 12, color: AppColors.navy),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScheduleXNoticePage(inspectionId: item.id),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Notice',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.errorRed,
                          ),
                        ),
                        Icon(Icons.arrow_forward, size: 12, color: AppColors.errorRed),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Live Countdown Dialog ────────────────────────────────────────────────────

class _RejectionBlockDialog extends StatefulWidget {
  final String inspectionId;
  final String businessName;
  final DateTime? deadline;
  final VoidCallback onViewNotice;

  const _RejectionBlockDialog({
    required this.inspectionId,
    required this.businessName,
    required this.deadline,
    required this.onViewNotice,
  });

  @override
  State<_RejectionBlockDialog> createState() => _RejectionBlockDialogState();
}

class _RejectionBlockDialogState extends State<_RejectionBlockDialog> {
  late Duration _remaining;
  late final _timer = _startTimer();

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
  }

  Duration _calcRemaining() {
    final target = widget.deadline ?? DateTime.now().add(const Duration(days: 7));
    final diff = target.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Timer _startTimer() {
    return Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _calcRemaining());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final timerColor = isExpired
        ? AppColors.errorRed
        : days <= 2
            ? AppColors.errorRed
            : AppColors.amber;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                color: AppColors.red50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gavel_rounded, color: AppColors.errorRed, size: 32),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Inspection Blocked',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              isExpired
                  ? 'The rectification deadline has passed.\nSection 33 violation may apply.'
                  : 'This instrument was rejected under Schedule X.\nMerchant must rectify defects before re-inspection.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Live Countdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: isExpired ? AppColors.red50 : (days <= 2 ? AppColors.red50 : AppColors.amber50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isExpired ? AppColors.red200 : (days <= 2 ? AppColors.red200 : AppColors.amber200),
                ),
              ),
              child: isExpired
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Deadline Expired',
                          style: TextStyle(
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined, color: timerColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Time Remaining',
                              style: TextStyle(
                                color: timerColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TimeBox(value: _pad(days), label: 'DAYS', color: timerColor),
                            _TimeSep(color: timerColor),
                            _TimeBox(value: _pad(hours), label: 'HRS', color: timerColor),
                            _TimeSep(color: timerColor),
                            _TimeBox(value: _pad(minutes), label: 'MIN', color: timerColor),
                            _TimeSep(color: timerColor),
                            _TimeBox(value: _pad(seconds), label: 'SEC', color: timerColor),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(color: AppColors.slate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onViewNotice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Notice',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _TimeBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _TimeSep extends StatelessWidget {
  final Color color;
  const _TimeSep({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Text(
        ':',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}
