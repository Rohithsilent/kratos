// lib/features/nutrition/presentation/widgets/ai_meal_suggestions_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/ai_coach_controller.dart';
import '../controllers/nutrition_intelligence_controller.dart';

class AiMealSuggestionsSection extends ConsumerWidget {
  const AiMealSuggestionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiCoachProvider);
    final macros = ref.watch(dailyMacroTotalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF22C55E).withValues(alpha: 0.03)
            : const Color(0xFF22C55E).withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: isDark ? 0.12 : 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.restaurant_rounded, color: Color(0xFF22C55E), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI MEAL SUGGESTIONS', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text('Remaining: ${macros.remainingCalories.round()} kcal · ${macros.remainingProtein.round()}g protein', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w500)),
            ])),
          ]),
          const SizedBox(height: 16),

          if (state.isSuggestionsLoading)
            _loadingState(context)
          else if (state.mealSuggestions != null && state.mealSuggestions!.isNotEmpty)
            _suggestionsContent(context, state.mealSuggestions!)
          else
            _emptyState(context, ref),
        ],
      ),
    );
  }

  Widget _loadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.colors.onSurface.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF22C55E), strokeWidth: 2)),
        const SizedBox(width: 12),
        Text('Finding meals for you...', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _suggestionsContent(BuildContext context, List<Map<String, dynamic>> suggestions) {
    return Column(
      children: suggestions.map((meal) {
        final name = meal['name'] as String? ?? 'Meal';
        final cal = (meal['calories'] as num?)?.toInt() ?? 0;
        final pro = (meal['protein'] as num?)?.toInt() ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.colors.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.04)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w700))),
            Text('$cal kcal', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text('${pro}g P', style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 10, fontWeight: FontWeight.w800)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(aiCoachProvider.notifier).fetchMealSuggestions(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.15)),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF22C55E), size: 14),
          SizedBox(width: 8),
          Text('GET MEAL SUGGESTIONS', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}
