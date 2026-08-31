import 'dart:ui';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final bool hasShadow;
  final double blurSigma;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 18.0,
    this.hasShadow = true,
    this.blurSigma = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Glassmorphism styling defaults based on design requirements
    final bg = backgroundColor ??
        (isDark
            ? const Color(0x941C2541) // Dark glass overlay
            : const Color(0x8CFFFFFF)); // rgba(255,255,255,0.55)

    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : const Color(0xCCFFFFFF)); // rgba(255,255,255,0.80)

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : const Color(0xFF0F172A).withValues(alpha: 0.06);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 35,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: 1.0),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(18.0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

