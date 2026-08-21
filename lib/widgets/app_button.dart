import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    EdgeInsets padding;
    double fontSize;
    double iconSize;
    double height;

    switch (size) {
      case AppButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
        fontSize = 13;
        iconSize = 16;
        height = 36;
        break;
      case AppButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
        fontSize = 16;
        iconSize = 20;
        height = 48;
        break;
      case AppButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 11);
        fontSize = 14;
        iconSize = 18;
        height = 42;
        break;
    }

    Color bgColor = Colors.transparent;
    Color textColor = Colors.white;
    BorderSide borderSide = BorderSide.none;
    Gradient? gradient;
    List<BoxShadow>? boxShadow;

    switch (variant) {
      case AppButtonVariant.secondary:
        bgColor = isDark ? const Color(0x33FFFFFF) : const Color(0xE6E2E8F0);
        textColor = AppColors.getTextPrimary(isDark);
        break;
      case AppButtonVariant.outline:
        bgColor = isDark ? const Color(0x1F14B8A6) : const Color(0x140EA5E9);
        textColor = isDark ? AppColors.primaryTeal : AppColors.primaryBlue;
        borderSide = BorderSide(
          color: (isDark ? AppColors.primaryTeal : AppColors.primaryBlue).withValues(alpha: 0.5),
          width: 1.2,
        );
        break;
      case AppButtonVariant.text:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.primaryTeal : AppColors.primaryBlue;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.danger;
        textColor = Colors.white;
        boxShadow = [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case AppButtonVariant.primary:
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0EA5E9), // Medical Blue
            Color(0xFF14B8A6), // Healthcare Teal
          ],
        );
        textColor = Colors.white;
        boxShadow = [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
        break;
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    return Container(
      height: height,
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: gradient == null ? bgColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: borderSide != BorderSide.none
                  ? Border(
                      top: borderSide,
                      bottom: borderSide,
                      left: borderSide,
                      right: borderSide,
                    )
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

