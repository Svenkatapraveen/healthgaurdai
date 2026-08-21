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
    Color border;

    switch (type) {
      case BadgeType.success:
        bg = isDark ? const Color(0x3310B981) : const Color(0x2610B981);
        fg = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
        border = const Color(0xFF10B981).withValues(alpha: 0.35);
        break;
      case BadgeType.warning:
        bg = isDark ? const Color(0x33F59E0B) : const Color(0x26F59E0B);
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        border = const Color(0xFFF59E0B).withValues(alpha: 0.35);
        break;
      case BadgeType.danger:
        bg = isDark ? const Color(0x33EF4444) : const Color(0x26EF4444);
        fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
        border = const Color(0xFFEF4444).withValues(alpha: 0.35);
        break;
      case BadgeType.info:
        bg = isDark ? const Color(0x330EA5E9) : const Color(0x260EA5E9);
        fg = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
        border = const Color(0xFF0EA5E9).withValues(alpha: 0.35);
        break;
      case BadgeType.primary:
        bg = isDark ? const Color(0x3314B8A6) : const Color(0x260EA5E9);
        fg = isDark ? AppColors.primaryTeal : AppColors.primaryBlue;
        border = (isDark ? AppColors.primaryTeal : AppColors.primaryBlue).withValues(alpha: 0.35);
        break;
      case BadgeType.neutral:
        bg = isDark ? const Color(0x3364748B) : const Color(0x2664748B);
        fg = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
        border = const Color(0xFF64748B).withValues(alpha: 0.25);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.0),
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

