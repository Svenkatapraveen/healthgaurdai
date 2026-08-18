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
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
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
      default:
        padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 11);
        fontSize = 14;
        iconSize = 18;
        height = 42;
        break;
    }

    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.secondary:
        bgColor = isDark ? AppColors.darkHover : const Color(0xFFE2E8F0);
        textColor = AppColors.getTextPrimary(isDark);
        break;
      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.primaryTeal : AppColors.primaryBlue;
        borderSide = BorderSide(
          color: isDark ? AppColors.primaryTeal : AppColors.primaryBlue,
          width: 1.5,
        );
        break;
      case AppButtonVariant.text:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.primaryTeal : AppColors.primaryBlue;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.danger;
        textColor = Colors.white;
        break;
      case AppButtonVariant.primary:
      default:
        bgColor = AppColors.primaryBlue;
        textColor = Colors.white;
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

    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: borderSide != BorderSide.none ? Border(
                top: borderSide, bottom: borderSide, left: borderSide, right: borderSide
              ) : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
