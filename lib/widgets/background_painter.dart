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
      duration: const Duration(seconds: 14),
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
        // Base gradient background
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
                        Color(0xFF0D1B2A),
                      ]
                    : const [
                        Color(0xFFF5FBFF),
                        Color(0xFFEEFAFF),
                        Color(0xFFF4FFFC),
                      ],
              ),
            ),
          ),
        ),

        // Animated subtle background ambient gradient blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final offset1 = math.sin(t * math.pi * 2) * 25.0;
            final offset2 = math.cos(t * math.pi * 2) * 30.0;

            return Stack(
              children: [
                // Top-left soft ice-blue blob
                Positioned(
                  left: -100 + offset1,
                  top: -80 + offset2,
                  child: Container(
                    width: 450,
                    height: 450,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF0EA5E9).withValues(alpha: 0.20),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF0EA5E9).withValues(alpha: 0.18),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),

                // Top-right healthcare teal blob
                Positioned(
                  right: -120 - offset2,
                  top: -100 + offset1,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF14B8A6).withValues(alpha: 0.18),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF14B8A6).withValues(alpha: 0.16),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),

                // Bottom-right subtle lavender / indigo blob
                Positioned(
                  right: -80 + offset1,
                  bottom: -120 - offset2,
                  child: Container(
                    width: 480,
                    height: 480,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF6366F1).withValues(alpha: 0.14),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF6366F1).withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),

                // Center-left gentle aqua blob
                Positioned(
                  left: -120 - offset2,
                  bottom: 150 + offset1,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF06B6D4).withValues(alpha: 0.12),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF06B6D4).withValues(alpha: 0.12),
                                Colors.transparent,
                              ],
                        stops: const [0.0, 0.75],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Forefront child application layer
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}
