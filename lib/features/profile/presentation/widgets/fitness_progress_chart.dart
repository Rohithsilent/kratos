import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_custom_colors.dart';

class FitnessProgressChart extends StatelessWidget {
  final List<double> dailyCalories;
  final List<String> labels;

  const FitnessProgressChart({
    super.key,
    required this.dailyCalories,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 220,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: AppDecorations.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-DAY ACTIVITY',
                style: AppTypography.labelBold.copyWith(
                  color: isDark ? context.customColors.grey400 : context.customColors.grey600,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CALORIES',
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Expanded(
            child: CustomPaint(
              size: Size(double.infinity, double.infinity),
              painter: _ChartPainter(
                values: dailyCalories,
                labels: labels,
                isDark: isDark,
                colors: context.colors,
                customColors: context.customColors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final bool isDark;
  final ColorScheme colors;
  final AppCustomColors customColors;

  _ChartPainter({
    required this.values,
    required this.labels,
    required this.isDark,
    required this.colors,
    required this.customColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final double chartHeight = size.height - 25; // leave space for bottom labels
    final double maxVal = values.isEmpty ? 1.0 : values.reduce(max);
    final double finalMaxVal = maxVal == 0 ? 100.0 : maxVal; // Avoid divide by 0, use standard height scale if all 0

    // Draw horizontal grid lines (3 grid levels)
    for (int i = 0; i <= 2; i++) {
      final double y = (chartHeight / 2) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Draw value labels next to grid line
      final valLabel = '${(finalMaxVal * (2 - i) / 2).round()}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: valLabel,
          style: TextStyle(
            color: isDark ? customColors.grey500.withOpacity(0.7) : customColors.grey600.withOpacity(0.7),
            fontSize: 8,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(4, y - 10));
    }

    if (values.isEmpty) return;

    // Map values to coordinates
    final double spacing = size.width / (values.length - 1);
    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = spacing * i;
      // Map so height is scaled nicely, with a small padding from the top grid line
      final double y = chartHeight - (chartHeight * 0.75 * (values[i] / finalMaxVal)) - 8;
      points.add(Offset(x, y));
    }

    // Draw bottom X labels (Mon, Tue, etc.)
    for (int i = 0; i < labels.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: isDark ? customColors.grey400 : customColors.grey600,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Center the label text at column X
      final xOffset = spacing * i - (textPainter.width / 2);
      textPainter.paint(
        canvas,
        Offset(
          xOffset.clamp(0, size.width - textPainter.width),
          size.height - 14,
        ),
      );
    }

    // Paint curve path
    final paint = Paint()
      ..color = colors.primary
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = colors.primary.withOpacity(0.3)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final controlX = (prev.dx + curr.dx) / 2;
      path.cubicTo(controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
    }

    // Draw dynamic path glow & line
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);

    // Paint gradient fill under the path
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, chartHeight);
    fillPath.lineTo(0, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.primary.withOpacity(isDark ? 0.16 : 0.08),
          colors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // Draw little dynamic glowing nodes at each point
    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final nodeBorder = Paint()
      ..color = colors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      // Draw node only if they worked out (non-zero value) or at ends
      if (values[i] > 0 || i == 0 || i == points.length - 1) {
        canvas.drawCircle(points[i], 3.5, nodePaint);
        canvas.drawCircle(points[i], 3.5, nodeBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.isDark != isDark || oldDelegate.labels != labels;
  }
}
