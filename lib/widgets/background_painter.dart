import 'dart:math' as math;
import 'package:flutter/material.dart';

class BackgroundPainter extends StatefulWidget {
  final Widget child;

  const BackgroundPainter({
    super.key,
    required this.child,
  });

  @override
  State<BackgroundPainter> createState() => _BackgroundPainterState();
}

class _BackgroundPainterState extends State<BackgroundPainter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base gradient background: Soft white to very light blue (Light Mode)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF070D19),
                        Color(0xFF0B132B),
                        Color(0xFF0F172A),
                      ]
                    : const [
                        Colors.white,
                        Color(0xFFF0F9FF), // Extremely light blue
                        Color(0xFFE0F2FE), // Very light soft blue
                      ],
              ),
            ),
          ),
        ),

        // Animated subtle background ambient gradient blobs (very soft blue glow)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final offset1 = math.sin(t * math.pi * 2) * 15.0;
            final offset2 = math.cos(t * math.pi * 2) * 20.0;

            return Stack(
              children: [
                // Top-left soft blue glow
                Positioned(
                  left: -120 + offset1,
                  top: -100 + offset2,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),

                // Top-right healthcare teal glow (very subtle)
                Positioned(
                  right: -150 - offset2,
                  top: -120 + offset1,
                  child: Container(
                    width: 550,
                    height: 550,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF14B8A6).withValues(alpha: 0.10),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF14B8A6).withValues(alpha: 0.06),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),

                // Bottom-right subtle lavender/blue glow
                Positioned(
                  right: -100 + offset1,
                  bottom: -150 - offset2,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF0EA5E9).withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Healthcare-themed custom paint layer (very faint crosses & lines)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: MedicalBackgroundPainter(
                  isDark: isDark,
                  animationValue: _controller.value,
                ),
              );
            },
          ),
        ),

        // Forefront child application layer
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}

class MedicalBackgroundPainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  MedicalBackgroundPainter({
    required this.isDark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw extremely faint grid of medical cross shapes
    final Color crossColor = isDark
        ? Colors.white.withValues(alpha: 0.02)
        : const Color(0xFF0EA5E9).withValues(alpha: 0.035);

    final Paint crossPaint = Paint()
      ..color = crossColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double stepX = 140.0;
    final double stepY = 140.0;
    final double crossSize = 7.0;

    for (double x = stepX / 2; x < size.width; x += stepX) {
      for (double y = stepY / 2; y < size.height; y += stepY) {
        if ((x.toInt() ~/ stepX + y.toInt() ~/ stepY) % 2 == 0) {
          canvas.drawLine(
            Offset(x - crossSize / 2, y),
            Offset(x + crossSize / 2, y),
            crossPaint,
          );
          canvas.drawLine(
            Offset(x, y - crossSize / 2),
            Offset(x, y + crossSize / 2),
            crossPaint,
          );
        }
      }
    }

    // 2. Draw extremely subtle modern waving tech curves
    final Color curveColor = isDark
        ? const Color(0xFF14B8A6).withValues(alpha: 0.015)
        : const Color(0xFF14B8A6).withValues(alpha: 0.025);

    final Paint curvePaint = Paint()
      ..color = curveColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double offset = animationValue * 2 * math.pi;

    // Top Wave Curve
    final Path path1 = Path();
    final double waveHeight1 = size.height * 0.22;
    path1.moveTo(0, waveHeight1);
    path1.cubicTo(
      size.width * 0.3,
      waveHeight1 + math.sin(offset) * 25,
      size.width * 0.7,
      waveHeight1 - math.cos(offset) * 25,
      size.width,
      waveHeight1 + 10,
    );
    canvas.drawPath(path1, curvePaint);

    // Bottom Wave Curve
    final Path path2 = Path();
    final double waveHeight2 = size.height * 0.78;
    path2.moveTo(0, waveHeight2);
    path2.cubicTo(
      size.width * 0.25,
      waveHeight2 - math.cos(offset) * 20,
      size.width * 0.75,
      waveHeight2 + math.sin(offset) * 20,
      size.width,
      waveHeight2 - 10,
    );
    canvas.drawPath(path2, curvePaint);
  }

  @override
  bool shouldRepaint(covariant MedicalBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.animationValue != animationValue;
  }
}
