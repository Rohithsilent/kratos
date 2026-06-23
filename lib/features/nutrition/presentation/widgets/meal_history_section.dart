// lib/features/nutrition/presentation/widgets/meal_history_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/enums/meal_type.dart';
import '../../domain/models/meal_entry_model.dart';
import '../controllers/meal_log_controller.dart';

class MealHistorySection extends ConsumerWidget {
  const MealHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(groupedMealsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEAL HISTORY',
            style: AppTypography.labelBold.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 14),
          groupedAsync.when(
            data: (grouped) {
              final total = grouped.values.fold<int>(0, (s, l) => s + l.length);
              if (total == 0) return _empty(context);
              return Column(
                children: MealType.values
                    .where((t) => (grouped[t] ?? []).isNotEmpty)
                    .map((t) => _CategoryCard(type: t, meals: grouped[t]!))
                    .toList(),
              );
            },
            loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (err, st) => _empty(context),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.04)),
      ),
      child: Row(children: [
        Icon(Icons.restaurant_menu_rounded, color: context.colors.onSurface.withValues(alpha: 0.12), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('No meals logged today.', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.25), fontSize: 11, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final MealType type;
  final List<MealEntry> meals;
  const _CategoryCard({required this.type, required this.meals});

  Color get _color => switch (type) {
    MealType.breakfast => const Color(0xFFFFB852),
    MealType.lunch => const Color(0xFF22C55E),
    MealType.dinner => const Color(0xFF8B5CF6),
    MealType.snack => const Color(0xFFFF6B6B),
  };

  IconData get _icon => switch (type) {
    MealType.breakfast => Icons.wb_sunny_rounded,
    MealType.lunch => Icons.wb_cloudy_rounded,
    MealType.dinner => Icons.nightlight_round,
    MealType.snack => Icons.cookie_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final totalCals = meals.fold<double>(0, (s, m) => s + m.calories);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.04)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Icon(_icon, color: _color, size: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(type.displayName.toUpperCase(), style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0))),
            Text('${totalCals.round()} kcal', style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w800)),
          ]),
        ),
        ...meals.map((meal) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.colors.onSurface.withValues(alpha: 0.03)))),
          child: Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: meal.source == 'ai_scan' ? const Color(0xFF8B5CF6) : context.colors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(meal.foodName, style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('P: ${meal.protein.round()}g · C: ${meal.carbs.round()}g · F: ${meal.fats.round()}g', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.25), fontSize: 9, fontWeight: FontWeight.w600)),
            ])),
            Text('${meal.calories.round()} kcal', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w800)),
          ]),
        )),
      ]),
    );
  }
}
