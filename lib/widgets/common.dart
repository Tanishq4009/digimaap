import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../routes.dart';
import '../services/connectivity_service.dart';

enum AppRole { consumer, inspector }

/// eMaap wordmark + logo glyph. Ported from `Brand` in emapp/index.tsx.
class Brand extends StatelessWidget {
  final bool compact;
  const Brand({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          width: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.navy, width: 3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: AppColors.saffron,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DigiMaap',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 18 : 20,
                letterSpacing: -0.3,
                height: 1,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 3),
              const Text(
                'LEGAL METROLOGY',
                style: TextStyle(
                  color: AppColors.blue100,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Top header row with back/brand, optional title and notification bell.
class AppHeader extends StatefulWidget {
  final AppRole? role;
  final String? title;

  const AppHeader({super.key, this.role, this.title});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (widget.title != null)
                  _circleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).maybePop(),
                  )
                else
                  const Brand(compact: true),
                if (widget.title != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.title!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.role == AppRole.inspector)
            ValueListenableBuilder<bool>(
              valueListenable: ConnectivityService().isOnline,
              builder: (context, isOnline, _) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (isOnline ? AppColors.success : Colors.red)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withAlpha(150),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 6,
                        width: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFCA5A5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          color: isOnline
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          _circleIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => Navigator.of(context).pushNamed(
              widget.role == AppRole.inspector
                  ? Routes.inspectorNotifications
                  : Routes.consumerNotifications,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 36,
        width: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

/// Thin tri-colour strip under the header (saffron / white / green).
class TriColorStrip extends StatelessWidget {
  const TriColorStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 3,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: AppColors.saffron)),
          Expanded(child: ColoredBox(color: Colors.white)),
          Expanded(child: ColoredBox(color: AppColors.success)),
        ],
      ),
    );
  }
}

class _NavItem {
  final String route;
  final String label;
  final IconData icon;
  const _NavItem(this.route, this.label, this.icon);
}

/// Bottom tab bar, mirrors `BottomNav` in emapp/index.tsx.
class BottomNav extends StatelessWidget {
  final AppRole role;
  const BottomNav({super.key, required this.role});

  static const _consumerItems = [
    _NavItem(Routes.consumerHome, 'Home', Icons.home_rounded),
    _NavItem(Routes.consumerHistory, 'History', Icons.history_rounded),
    _NavItem(
      Routes.consumerNotifications,
      'Alerts',
      Icons.notifications_none_rounded,
    ),
    _NavItem(Routes.consumerProfile, 'Profile', Icons.person_outline_rounded),
  ];

  static const _inspectorItems = [
    _NavItem(Routes.inspectorHome, 'Home', Icons.home_rounded),
    _NavItem(
      Routes.inspectorInspections,
      'Inspections',
      Icons.description_outlined,
    ),
    _NavItem(Routes.inspectorSync, 'Sync', Icons.wifi_rounded),
    _NavItem(Routes.inspectorProfile, 'Profile', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final items = role == AppRole.consumer ? _consumerItems : _inspectorItems;
    final current = ModalRoute.of(context)?.settings.name;

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: items.map((item) {
              final active = current == item.route;
              return Expanded(
                child: InkWell(
                  onTap: active
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil(item.route, (r) => false),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: active ? AppColors.navy : AppColors.slate400,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: active ? AppColors.navy : AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class Shell extends StatelessWidget {
  final Widget child;
  final AppRole? role;
  final String? title;
  final bool nav;
  final Color? backgroundColor;

  const Shell({
    super.key,
    required this.child,
    this.role,
    this.title,
    this.nav = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final showNav = nav && role != null;
    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor ?? AppColors.background,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.navy,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  AppHeader(role: role, title: title),
                  const TriColorStrip(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showNav ? 90.0 : 0.0),
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: showNav ? BottomNav(role: role!) : null,
    );
  }
}

/// Primary CTA button, mirrors `PrimaryButton`.
class PrimaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool secondary;

  const PrimaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final Color bg = disabled
        ? AppColors.slate200
        : secondary
        ? Colors.white
        : AppColors.saffron;
    final Color fg = disabled
        ? AppColors.slate400
        : secondary
        ? AppColors.navy
        : Colors.white;

    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: bg,
        gradient: (!disabled && !secondary)
            ? LinearGradient(
                colors: [AppColors.saffron, AppColors.amber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: (!disabled && !secondary)
            ? [
                BoxShadow(
                  color: AppColors.saffron.withAlpha(120),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        border: secondary ? Border.all(color: AppColors.slate200) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              child: IconTheme(
                data: IconThemeData(color: fg, size: 18),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stylised QR-code-like pattern, ported from the deterministic SVG generator.
class QRPattern extends StatelessWidget {
  const QRPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(painter: _QRPainter()),
      ),
    );
  }
}

class _QRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cols = 11;
    final cell = size.width / cols;
    final paint = Paint()..color = AppColors.navy;
    for (int i = 0; i < cols * cols; i++) {
      final x = i % cols;
      final y = i ~/ cols;
      final finder = (x < 3 && y < 3) || (x > 7 && y < 3) || (x < 3 && y > 7);
      final noisy = (i * 17 + x * 5 + y) % 7 < 3;
      if (finder || noisy) {
        final rect = Rect.fromLTWH(
          x * cell,
          y * cell,
          cell * 0.85,
          cell * 0.85,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Government footer card, mirrors `FooterStrip`.
class FooterStrip extends StatelessWidget {
  const FooterStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          const Text(
            'DigiMaap · Digital Legal Metrology',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Government of India · Ministry of Consumer Affairs\nDepartment of Legal Metrology',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, fontSize: 10, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Digital India · MeitY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.slate400,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Labeled text field row, mirrors `Field`.
class AppField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const AppField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: AppColors.slate400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small helper for the two-column info grid used across detail screens.
class InfoGridItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoGridItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.slate400,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}
