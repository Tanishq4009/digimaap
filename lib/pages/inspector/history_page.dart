import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../../models/data.dart';
import 'inspection_detail_page.dart';

class InspectorHistoryPage extends StatefulWidget {
  const InspectorHistoryPage({super.key});

  @override
  State<InspectorHistoryPage> createState() => _InspectorHistoryPageState();
}

class _InspectorHistoryPageState extends State<InspectorHistoryPage> {
  final _query = TextEditingController();

  // (id, label) pairs — id is what actually opens the right detail page.
  static const staticRows = [
    ('LM-260112-04', 'Sharma Fuel & Weighing Services · LM-260112-04'),
    ('LM-260110-18', 'Bhopal Retail Mart · LM-260110-18'),
    ('LM-260108-11', 'Bharat Weighing House · LM-260108-11'),
  ];

  @override
  Widget build(BuildContext context) {
    final q = _query.text.toLowerCase();

    return Shell(
      role: AppRole.inspector,
      title: 'Inspection history',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(125),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.slate400,
                    size: 17,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'Search inspections',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<List<String>>(
              valueListenable: liveInspectionIds,
              builder: (context, liveIds, _) {
                return ValueListenableBuilder<List<String>>(
                  valueListenable: inspectedInspectionIds,
                  builder: (context, inspectedIds, _) {
                    final liveRows = liveIds.map((id) {
                      final item = inspectionFor(id);
                      return (id, '${item.business} · $id');
                    }).toList();

                    final inspectedRows = inspectedIds.map((id) {
                      final item = inspectionFor(id);
                      return (id, '${item.business} · $id');
                    }).toList();

                    final allRows = [
                      ...inspectedRows,
                      ...liveRows,
                      ...staticRows,
                    ];
                    final shown = allRows
                        .where((r) => r.$2.toLowerCase().contains(q))
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final row in shown) ...[
                          _HistoryRow(
                            id: row.$1,
                            label: row.$2,
                            isLive: liveIds.contains(row.$1),
                            isInspected: inspectedIds.contains(row.$1),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const Center(
                          child: Text(
                            'All assigned records loaded',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String id;
  final String label;
  final bool isLive;
  final bool isInspected;
  const _HistoryRow({
    required this.id,
    required this.label,
    required this.isLive,
    this.isInspected = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = label.split(' · ');
    final Color borderColor = isLive
        ? AppColors.errorRed
        : isInspected
        ? AppColors.success
        : AppColors.slate200;
    final Color iconBg = isLive
        ? AppColors.red50
        : isInspected
        ? AppColors.green50
        : AppColors.green50;
    final Color iconColor = isLive ? AppColors.errorRed : AppColors.success;
    final IconData iconData = isLive
        ? Icons.bolt_rounded
        : isInspected
        ? Icons.verified_rounded
        : Icons.fact_check_outlined;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InspectionDetailPage(inspectionId: id),
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
              color: isLive
                  ? AppColors.errorRed.withAlpha(150)
                  : Colors.black.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: (isLive || isInspected)
              ? Border.all(color: borderColor, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          parts[0],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (isInspected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.green50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Inspected',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLive
                        ? 'Just now · Live request'
                        : isInspected
                        ? 'Seal submitted · Just now'
                        : '${parts.length > 1 ? parts[1] : ''} · 10 Jan 2026',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}
