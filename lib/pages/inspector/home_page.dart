import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import '../../routes.dart';
import 'inspection_detail_page.dart';
import '../../services/connectivity_service.dart';

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
                  // NEW: live socket requests (if any) render on top, followed by
                  // the two default sample inspections — all via the same card.
                  ValueListenableBuilder<List<String>>(
                    valueListenable: liveInspectionIds,
                    builder: (context, liveIds, _) {
                      final ids = [...liveIds, 'LM-260112-04', 'LM-260112-05'];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final id in ids) ...[
                            _InspectionCard(item: inspectionFor(id)),
                            const SizedBox(height: 12),
                          ],
                        ],
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
class _InspectionCard extends StatelessWidget {
  final InspectionData item;
  const _InspectionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InspectionDetailPage(inspectionId: item.id),
        ),
      ),
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
                  : Colors.black.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: item.isLive
              ? Border.all(color: AppColors.errorRed, width: 1.5)
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
                    color: item.isLive ? AppColors.red50 : AppColors.orange50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.priority,
                    style: TextStyle(
                      color: item.isLive
                          ? AppColors.errorRed
                          : AppColors.saffron,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
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
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    Icon(Icons.arrow_forward, size: 12, color: AppColors.navy),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
