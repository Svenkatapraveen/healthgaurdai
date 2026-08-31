import 'package:flutter/material.dart';

class AppColors {
  // Theme Primary Colors - Refined Healthcare Glassmorphism Palette
  static const Color primaryBlue = Color(0xFF0EA5E9); // Medical Blue
  static const Color navyDark = Color(0xFF0F172A); // Dark Slate
  static const Color primaryTeal = Color(0xFF14B8A6); // Healthcare Teal
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color accentCyan = Color(0xFF0EA5E9);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Risk Indicator Colors
  static const Color riskLow = Color(0xFF10B981);
  static const Color riskModerate = Color(0xFFF59E0B);
  static const Color riskHigh = Color(0xFFEF4444);
  static const Color riskCritical = Color(0xFFDC2626);

  // Light Mode Colors (Soft Ice Blue / Medical Blue background)
  static const Color lightBg = Color(0xFFF7FCFF);
  static const Color lightSurface = Color(0x94FFFFFF); // ~0.58 white glass
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xBFFFFFFF); // ~0.75 white border
  static const Color lightHover = Color(0x1A0EA5E9);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0B132B);
  static const Color darkSurface = Color(0x941C2541);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0x33FFFFFF);
  static const Color darkHover = Color(0x2214B8A6);

  // Helper getters depending on brightness
  static Color getBg(bool isDark) => isDark ? darkBg : lightBg;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color getHover(bool isDark) => isDark ? darkHover : lightHover;

  // Gradients for modern Glassmorphism UI elements
  static LinearGradient glassGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF1C2541).withValues(alpha: 0.65),
              const Color(0xFF0B132B).withValues(alpha: 0.50),
            ]
          : [
              Colors.white.withValues(alpha: 0.68),
              Colors.white.withValues(alpha: 0.48),
            ],
    );
  }

  static LinearGradient heroGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9),
      Color(0xFF14B8A6),
    ],
  );

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9),
      Color(0xFF14B8A6),
    ],
  );
}
