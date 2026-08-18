import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum BadgeType { success, warning, danger, info, neutral, primary }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;
  final bool isSmall;

  const AppBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.icon,
    this.isSmall = false,
  });

  factory AppBadge.status(String status) {
    final lower = status.toLowerCase();
    BadgeType bType;
    if (lower.contains('approved') || lower.contains('completed') || lower.contains('active')) {
      bType = BadgeType.success;
    } else if (lower.contains('pending') || lower.contains('scheduled')) {
      bType = BadgeType.warning;
    } else if (lower.contains('rejected') || lower.contains('cancelled') || lower.contains('critical')) {
      bType = BadgeType.danger;
    } else if (lower.contains('rescheduled')) {
      bType = BadgeType.info;
    } else {
      bType = BadgeType.neutral;
    }
    return AppBadge(label: status, type: bType);
  }

  factory AppBadge.risk(String risk) {
    final lower = risk.toLowerCase();
    BadgeType bType;
    if (lower.contains('low')) {
      bType = BadgeType.success;
    } else if (lower.contains('moderate') || lower.contains('medium')) {
      bType = BadgeType.warning;
    } else if (lower.contains('high') || lower.contains('critical')) {
      bType = BadgeType.danger;
    } else {
      bType = BadgeType.info;
    }
    return AppBadge(label: 'Risk: $risk', type: bType);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.success:
        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
        fg = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46);
        break;
      case BadgeType.warning:
        bg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
        break;
      case BadgeType.danger:
        bg = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2);
        fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        break;
      case BadgeType.info:
        bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
        fg = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF);
        break;
      case BadgeType.primary:
        bg = isDark ? const Color(0xFF0F2C59) : const Color(0xFFE0F2FE);
        fg = isDark ? AppColors.primaryTeal : AppColors.primaryBlue;
        break;
      case BadgeType.neutral:
        bg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        fg = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 10 : 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
