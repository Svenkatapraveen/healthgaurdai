import 'package:flutter/material.dart';

class AppColors {
  // Theme Primary Colors
  static const Color primaryBlue = Color(0xFF0F2C59); // Deep Navy / Medical Blue
  static const Color navyDark = Color(0xFF0A192F);
  static const Color primaryTeal = Color(0xFF00A896); // Teal / Healthcare Cyan
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color accentCyan = Color(0xFF0EA5E9);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Risk Indicator Colors
  static const Color riskLow = Color(0xFF10B981);
  static const Color riskModerate = Color(0xFFF59E0B);
  static const Color riskHigh = Color(0xFFF97316);
  static const Color riskCritical = Color(0xFFEF4444);

  // Light Mode Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightHover = Color(0xFFF1F5F9);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF1C2541);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkHover = Color(0xFF1E293B);

  // Helper getters depending on brightness
  static Color getBg(bool isDark) => isDark ? darkBg : lightBg;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color getHover(bool isDark) => isDark ? darkHover : lightHover;

  // Gradients for subtle modern UI elements
  static LinearGradient glassGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF1C2541).withOpacity(0.8),
              const Color(0xFF0B132B).withOpacity(0.8),
            ]
          : [
              Colors.white.withOpacity(0.9),
              const Color(0xFFF8FAFC).withOpacity(0.9),
            ],
    );
  }

  static LinearGradient heroGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F2C59),
      Color(0xFF0A192F),
    ],
  );

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0F2C59),
      Color(0xFF00A896),
    ],
  );
}
