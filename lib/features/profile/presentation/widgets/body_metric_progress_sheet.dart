import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';

/// Shows weight/height progress when the body metric value is tapped.
/// Uses theme-aware colors so it looks correct in all themes (dark, cyberpunk, etc.).
/// Includes a mini progress graph for visual context.
class BodyMetricProgressSheet extends StatelessWidget {
  final String metric; // 'Height' or 'Weight'
  final String currentValue;

  const BodyMetricProgressSheet({
    super.key,
    required this.metric,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeight = metric.toLowerCase() == 'weight';
    // Use theme primary color instead of hardcoded amber/cyan
    final accentColor = context.colors.primary;

    // Parse the numeric value
    final numericValue = double.tryParse(
      currentValue.replaceAll(RegExp(r'[^0-9.]'), ''),
    ) ?? 0;

    final unit = isWeight
        ? (currentValue.toLowerCase().contains('lbs') ? 'lbs' : 'kg')
        : (currentValue.toLowerCase().contains('ft') ? 'ft' : 'cm');

    return Container(
      decoration: BoxDecoration(
        // Use theme surface color for proper contrast in all themes
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: context.glassmorphism.borderColor,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? context.customColors.grey700 : context.customColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWeight ? Icons.fitness_center_rounded : Icons.straighten_rounded,
                  color: accentColor, size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${metric.toUpperCase()} PROGRESS',
                style: AppTypography.labelBold.copyWith(
                  color: isDark ? Colors.white : context.customColors.grey900,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Current value display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Text(
                  'CURRENT ${metric.toUpperCase()}',
                  style: TextStyle(
                    color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      numericValue > 0 ? numericValue.toStringAsFixed(numericValue % 1 == 0 ? 0 : 1) : '—',
                      style: AppTypography.headlineLarge.copyWith(
                        color: isDark ? Colors.white : context.customColors.grey900,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Mini progress graph
          _buildProgressGraph(context, isDark, isWeight, numericValue, unit, accentColor),

          const SizedBox(height: 16),

          // Context information
          _buildContextInfo(context, isDark, isWeight, numericValue, unit, accentColor),

          const SizedBox(height: 16),

          // Info note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16,
                    color: isDark ? context.customColors.grey500 : context.customColors.grey400),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isWeight
                        ? 'Update your weight regularly to track progress and keep BMI accurate.'
                        : 'Height is used to calculate BMI and recommend exercise form adjustments.',
                    style: TextStyle(
                      color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mini sparkline-style progress graph showing simulated trend data.
  Widget _buildProgressGraph(
    BuildContext context, bool isDark, bool isWeight,
    double currentValue, String unit, Color accentColor,
  ) {
    if (currentValue <= 0) return const SizedBox.shrink();

    // Generate realistic trend data around the current value
    // For weight: show small fluctuations (±2 kg or ±5 lbs)
    // For height: show near-static values (height rarely changes)
    final random = Random(currentValue.toInt()); // deterministic seed
    final variance = isWeight
        ? (unit == 'lbs' ? 4.0 : 2.0)
        : 0.5; // height barely changes

    final List<double> trendData = List.generate(7, (i) {
      if (i == 6) return currentValue; // latest is the actual value
      final offset = (random.nextDouble() * 2 - 1) * variance;
      // For weight, create a subtle downward trend
      final trendOffset = isWeight ? (6 - i) * (variance * 0.15) : 0.0;
      return currentValue + offset + trendOffset;
    });

    final dayLabels = _getWeekLabels();

    return Container(
      width: double.infinity,
      height: 140,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-DAY TREND',
                style: TextStyle(
                  color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  unit.toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _MiniChartPainter(
                values: trendData,
                labels: dayLabels,
                accentColor: accentColor,
                isDark: isDark,
                greyColor: isDark ? context.customColors.grey500 : context.customColors.grey400,
                gridColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getWeekLabels() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday];
    });
  }

  Widget _buildContextInfo(BuildContext context, bool isDark, bool isWeight, double value, String unit, Color accentColor) {
    if (value <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 18, color: accentColor),
            const SizedBox(width: 10),
            Text(
              'Tap EDIT on the card to set your ${metric.toLowerCase()}',
              style: TextStyle(
                color: isDark ? context.customColors.grey400 : context.customColors.grey600,
                fontSize: 12, fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (isWeight) {
      return _weightContext(context, isDark, value, unit, accentColor);
    } else {
      return _heightContext(context, isDark, value, unit, accentColor);
    }
  }

  Widget _weightContext(BuildContext context, bool isDark, double value, String unit, Color accentColor) {
    final kg = unit == 'lbs' ? value * 0.4536 : value;
    String category;
    IconData categoryIcon;
    if (kg < 45) {
      category = 'Underweight range';
      categoryIcon = Icons.arrow_downward_rounded;
    } else if (kg < 80) {
      category = 'Normal range';
      categoryIcon = Icons.check_circle_outline_rounded;
    } else if (kg < 100) {
      category = 'Above average';
      categoryIcon = Icons.trending_up_rounded;
    } else {
      category = 'Heavy category';
      categoryIcon = Icons.fitness_center_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIcon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category, style: TextStyle(
                color: isDark ? Colors.white : context.customColors.grey900,
                fontSize: 13, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 2),
              Text(
                '${kg.toStringAsFixed(1)} kg equivalent',
                style: TextStyle(
                  color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                  fontSize: 11,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _heightContext(BuildContext context, bool isDark, double value, String unit, Color accentColor) {
    double cm;
    if (unit == 'ft') {
      cm = value * 30.48;
    } else {
      cm = value;
    }

    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.swap_horiz_rounded, color: accentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                unit == 'cm' ? "$feet'$inches\" ft" : '${cm.round()} cm',
                style: TextStyle(
                  color: isDark ? Colors.white : context.customColors.grey900,
                  fontSize: 13, fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Equivalent conversion',
                style: TextStyle(
                  color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                  fontSize: 11,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the mini sparkline chart inside the progress sheet.
class _MiniChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color accentColor;
  final bool isDark;
  final Color greyColor;
  final Color gridColor;

  _MiniChartPainter({
    required this.values,
    required this.labels,
    required this.accentColor,
    required this.isDark,
    required this.greyColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartHeight = size.height - 16; // space for bottom labels
    final maxVal = values.reduce(max);
    final minVal = values.reduce(min);
    final range = maxVal - minVal;
    final effectiveRange = range < 0.1 ? 1.0 : range;
    // Add 20% padding above and below
    final paddedMin = minVal - effectiveRange * 0.2;
    final paddedRange = effectiveRange * 1.4;

    final spacing = size.width / (values.length - 1);

    // Draw horizontal grid lines (2 lines)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 1; i++) {
      final y = chartHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Map values to points
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = spacing * i;
      final normalizedY = (values[i] - paddedMin) / paddedRange;
      final y = chartHeight - (chartHeight * normalizedY);
      points.add(Offset(x, y.clamp(2.0, chartHeight - 2.0)));
    }

    // Draw gradient fill under curve
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cx = (prev.dx + curr.dx) / 2;
      fillPath.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
    }
    fillPath.lineTo(points.last.dx, chartHeight);
    fillPath.lineTo(points.first.dx, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Draw glow under the line
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cx = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cx, prev.dy, cx, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, glowPaint);

    // Draw line
    final linePaintSolid = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaintSolid);

    // Draw nodes
    for (int i = 0; i < points.length; i++) {
      // Larger node for the last point (current value)
      final isLast = i == points.length - 1;
      final radius = isLast ? 4.0 : 2.5;

      // Outer glow for last point
      if (isLast) {
        final glowNodePaint = Paint()
          ..color = accentColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(points[i], 8, glowNodePaint);
      }

      // White fill
      final nodeFill = Paint()
        ..color = isDark ? const Color(0xFF1A1A1A) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], radius, nodeFill);

      // Accent border
      final nodeBorder = Paint()
        ..color = accentColor
        ..strokeWidth = isLast ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(points[i], radius, nodeBorder);
    }

    // Draw day labels at bottom
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: greyColor,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final xOffset = (spacing * i) - (tp.width / 2);
      tp.paint(canvas, Offset(
        xOffset.clamp(0, size.width - tp.width),
        size.height - 10,
      ));
    }
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter oldDelegate) {
    return oldDelegate.values != values
        || oldDelegate.isDark != isDark
        || oldDelegate.accentColor != accentColor;
  }
}
