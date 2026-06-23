// lib/features/daily_planner/presentation/widgets/nutrition_tracker_card.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/nutrition/presentation/widgets/food_scanner_sheet.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_controller.dart';

class NutritionTrackerCard extends ConsumerWidget {
  const NutritionTrackerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(todayNutritionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.push('/nutrition'),
                child: Row(
                  children: [
                    Text(
                      'NUTRITION INTAKE',
                      style: AppTypography.labelBold.copyWith(
                        color: context.colors.onSurface,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: context.colors.onSurface.withValues(alpha: 0.2),
                        size: 10),
                  ],
                ),
              ),
              Row(
                children: [
                  // AI Scan button
                  GestureDetector(
                    onTap: () => FoodScannerSheet.show(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: context.customColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.document_scanner_rounded, color: Colors.white, size: 11),
                          SizedBox(width: 4),
                          Text(
                            'AI SCAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // LOG button
                  GestureDetector(
                    onTap: () => _showQuickLogSheet(context, ref),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: context.colors.primary, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'LOG',
                            style: TextStyle(
                              color: context.colors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _MacroCapsule(
                label: 'CALORIES',
                value: '${nutrition.caloriesConsumed.round()}',
                target: '${nutrition.caloriesTarget.round()}',
                unit: 'kcal',
                progress: nutrition.caloriesProgress,
                color: context.colors.primary,
              ),
              SizedBox(width: 8),
              _MacroCapsule(
                label: 'PROTEIN',
                value: '${nutrition.proteinConsumed.round()}',
                target: '${nutrition.proteinTarget.round()}',
                unit: 'g',
                progress: nutrition.proteinProgress,
                color: Color(0xFFFF6B6B),
              ),
              SizedBox(width: 8),
              _MacroCapsule(
                label: 'CARBS',
                value: '${nutrition.carbsConsumed.round()}',
                target: '${nutrition.carbsTarget.round()}',
                unit: 'g',
                progress: nutrition.carbsProgress,
                color: Color(0xFFFFB852),
              ),
              SizedBox(width: 8),
              _MacroCapsule(
                label: 'FATS',
                value: '${nutrition.fatsConsumed.round()}',
                target: '${nutrition.fatsTarget.round()}',
                unit: 'g',
                progress: nutrition.fatsProgress,
                color: Color(0xFF52D8FF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQuickLogSheet(BuildContext context, WidgetRef ref) {
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF0F0F0F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUICK LOG MACROS',
                style: TextStyle(color: context.colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _buildInput(context, 'Calories', calCtrl, 'kcal')),
                  SizedBox(width: 10),
                  Expanded(child: _buildInput(context, 'Protein', proCtrl, 'g')),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInput(context, 'Carbs', carbCtrl, 'g')),
                  SizedBox(width: 10),
                  Expanded(child: _buildInput(context, 'Fats', fatCtrl, 'g')),
                ],
              ),
              SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(nutritionLogProvider.notifier).logMacros(
                      calories: double.tryParse(calCtrl.text) ?? 0,
                      protein: double.tryParse(proCtrl.text) ?? 0,
                      carbs: double.tryParse(carbCtrl.text) ?? 0,
                      fats: double.tryParse(fatCtrl.text) ?? 0,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'LOG ENTRY',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput(BuildContext context, String label, TextEditingController ctrl, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.35),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: context.colors.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.06)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: context.colors.onSurface, fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.3), fontSize: 10),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.15)),
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroCapsule extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final String unit;
  final double progress;
  final Color color;

  const _MacroCapsule({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: context.colors.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.04)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular progress
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(40, 40),
                    painter: _MacroRingPainter(
                      progress: progress,
                      color: color,
                      bgColor: context.colors.onSurface.withValues(alpha: 0.04),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Value
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(color: context.colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '/ $target $unit',
                style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.25),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.3),
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _MacroRingPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    // Background
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter old) =>
      old.progress != progress || old.color != color;
}
