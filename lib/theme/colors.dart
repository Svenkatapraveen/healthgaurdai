import 'package:flutter/material.dart';

class AppColors {
  // Theme Primary Colors
  static const Color primaryBlue = Color(0xFF0F2C59);
  static const Color primaryTeal = Color(0xFF00C49F);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentCyan = Color(0xFF00BCD4);
  
  // Risk Indicator Colors
  static const Color riskLow = Color(0xFF4CAF50);
  static const Color riskModerate = Color(0xFFFFA000);
  static const Color riskHigh = Color(0xFFE65100);
  static const Color riskCritical = Color(0xFFD32F2F);

  // Light Mode Colors
  static const Color lightBg = Color(0xFFF4F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0A1128);
  static const Color darkSurface = Color(0xFF101F42);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF1E293B);

  // Helper getters depending on brightness
  static Color getBg(bool isDark) => isDark ? darkBg : lightBg;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;

  // Gradients for glassmorphism
  static LinearGradient glassGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Color(0xFF1E294B).withOpacity(0.4),
              Color(0xFF0F172A).withOpacity(0.4),
            ]
          : [
              Colors.white.withOpacity(0.7),
              Colors.white.withOpacity(0.3),
            ],
    );
  }
}
