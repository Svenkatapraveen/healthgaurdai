import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum ChartType { line, bar, gauge }

class CustomChart extends StatelessWidget {
  final List<double> dataPoints;
  final List<String> labels;
  final ChartType type;
  final Color? color;
  final List<Color>? gradientColors;
  final double height;
  final String title;
  final double maxValue;

  const CustomChart({
    Key? key,
    required this.dataPoints,
    required this.labels,
    this.type = ChartType.line,
    this.color,
    this.gradientColors,
    this.height = 180.0,
    this.title = '',
    this.maxValue = 100.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = color ?? AppColors.primaryTeal;
    final defaultGradients = gradientColors ?? [themeColor, themeColor.withOpacity(0.2)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.fastOutSlowIn,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ChartPainter(
                  dataPoints: dataPoints,
                  labels: labels,
                  type: type,
                  themeColor: themeColor,
                  gradients: defaultGradients,
                  animationValue: value,
                  isDark: isDark,
                  maxValue: maxValue,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final ChartType type;
  final Color themeColor;
  final List<Color> gradients;
  final double animationValue;
  final bool isDark;
  final double maxValue;

  _ChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.type,
    required this.themeColor,
    required this.gradients,
    required this.animationValue,
    required this.isDark,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    if (type == ChartType.gauge) {
      _paintGauge(canvas, size);
    } else if (type == ChartType.bar) {
      _paintBarChart(canvas, size);
    } else {
      _paintLineChart(canvas, size);
    }
  }

  void _paintGauge(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = math.min(size.width / 2, size.height - 40);

    // Draw background arc
    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Draw active colored segments based on dataPoints[0] (which is the health score)
    final double value = dataPoints[0] / maxValue;
    final double targetValue = value * animationValue;

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    // Set colors based on risk levels
    if (dataPoints[0] >= 80) {
      activePaint.color = AppColors.riskLow;
    } else if (dataPoints[0] >= 60) {
      activePaint.color = AppColors.riskModerate;
    } else if (dataPoints[0] >= 40) {
      activePaint.color = AppColors.riskHigh;
    } else {
      activePaint.color = AppColors.riskCritical;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * targetValue,
      false,
      activePaint,
    );

    // Draw value text
    final textPainter = TextPainter(
      text: TextSpan(
        text: (dataPoints[0] * animationValue).toStringAsFixed(0),
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height - 10),
    );

    // Draw title/label under value
    if (labels.isNotEmpty) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[0],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(center.dx - labelPainter.width / 2, center.dy - 10),
      );
    }
  }

  void _paintBarChart(Canvas canvas, Size size) {
    final double chartHeight = size.height - 30; // space for labels
    final double barWidth = (size.width / dataPoints.length) * 0.5;
    final double spacing = (size.width / dataPoints.length) * 0.5;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      double y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < dataPoints.length; i++) {
      double pct = dataPoints[i] / maxValue;
      double height = chartHeight * pct * animationValue;
      double x = spacing / 2 + i * (barWidth + spacing);
      double y = chartHeight - height;

      // Color coding logic
      Color col = themeColor;
      if (maxValue == 100) {
        if (dataPoints[i] > 80) col = AppColors.riskLow;
        else if (dataPoints[i] > 50) col = AppColors.riskModerate;
        else col = AppColors.riskCritical;
      }

      barPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [col, col.withOpacity(0.4)],
      ).createShader(Rect.fromLTWH(x, y, barWidth, height));

      // Draw rounded rect bar
      RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, height),
        Radius.circular(6),
      );
      canvas.drawRRect(rrect, barPaint);

      // Draw value on top of bar
      final valPainter = TextPainter(
        text: TextSpan(
          text: dataPoints[i].toStringAsFixed(0),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valPainter.layout();
      valPainter.paint(
        canvas,
        Offset(x + (barWidth - valPainter.width) / 2, y - 14),
      );

      // Draw label
      if (i < labels.length) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(x + (barWidth - labelPainter.width) / 2, chartHeight + 8),
        );
      }
    }
  }

  void _paintLineChart(Canvas canvas, Size size) {
    final double chartHeight = size.height - 35;
    final double stepX = size.width / (dataPoints.length - 1);

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)
      ..strokeWidth = 1.0;

    // Draw Grid Lines
    for (int i = 0; i <= 4; i++) {
      double y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    // Calculate coordinates
    final List<Offset> points = [];
    for (int i = 0; i < dataPoints.length; i++) {
      double x = i * stepX;
      double pct = dataPoints[i] / maxValue;
      double y = chartHeight - (chartHeight * pct * animationValue);
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, chartHeight);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      // Curve path using control points (Bezier)
      final controlX = p1.dx + (p2.dx - p1.dx) / 2;
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
      fillPath.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.close();

    // Fill Paint (Gradient)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          themeColor.withOpacity(0.35),
          themeColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Line Paint
    final linePaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw points & labels
    final pointPaint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.fill;
    final innerPointPaint = Paint()
      ..color = isDark ? AppColors.darkSurface : Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 6.0, pointPaint);
      canvas.drawCircle(points[i], 3.0, innerPointPaint);

      // Draw values on hover/point
      final valPainter = TextPainter(
        text: TextSpan(
          text: dataPoints[i].toStringAsFixed(0),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valPainter.layout();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(points[i].dx - valPainter.width / 2 - 4, points[i].dy - 22, valPainter.width + 8, valPainter.height + 2),
          Radius.circular(4),
        ),
        Paint()..color = (isDark ? AppColors.darkSurface : Colors.white).withOpacity(0.8),
      );
      valPainter.paint(canvas, Offset(points[i].dx - valPainter.width / 2, points[i].dy - 21));

      // Draw label
      if (i < labels.length) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(points[i].dx - labelPainter.width / 2, chartHeight + 10),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.dataPoints != dataPoints ||
        oldDelegate.isDark != isDark;
  }
}
