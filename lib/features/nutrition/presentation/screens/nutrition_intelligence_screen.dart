// lib/features/nutrition/presentation/screens/nutrition_intelligence_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../widgets/nutrition_score_section.dart';
import '../widgets/macro_dashboard_section.dart';
import '../widgets/hydration_intelligence_section.dart';
import '../widgets/protein_analysis_section.dart';
import '../widgets/ai_coach_section.dart';
import '../widgets/meal_history_section.dart';
import '../widgets/macro_pie_chart.dart';
import '../widgets/weekly_calories_chart.dart';
import '../widgets/ai_meal_suggestions_section.dart';
import '../widgets/food_scanner_sheet.dart';

class NutritionIntelligenceScreen extends ConsumerWidget {
  const NutritionIntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ═══ Ambient Background Glows ═══
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 400,
            left: -100,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ═══ Main Content ═══
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ──── Header ────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: context.colors.onSurface
                                      .withValues(alpha: 0.04),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.colors.onSurface
                                        .withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: context.colors.onSurface
                                      .withValues(alpha: 0.5),
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NUTRITION',
                                    style: TextStyle(
                                      color: context.colors.onSurface,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'INTELLIGENCE',
                                    style: TextStyle(
                                      color: context.colors.primary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // AI Scan FAB
                            GestureDetector(
                              onTap: () =>
                                  FoodScannerSheet.show(context),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient:
                                      context.customColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.colors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.document_scanner_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Actionable insights. Not just numbers.',
                          style: TextStyle(
                            color: context.colors.onSurface
                                .withValues(alpha: 0.3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 1: Nutrition Score ────
                const SliverToBoxAdapter(
                  child: NutritionScoreSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 2: Daily Macro Dashboard ────
                const SliverToBoxAdapter(
                  child: MacroDashboardSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 3: Hydration Intelligence ────
                const SliverToBoxAdapter(
                  child: HydrationIntelligenceSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 4: Protein Analysis ────
                const SliverToBoxAdapter(
                  child: ProteinAnalysisSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 5: AI Nutrition Coach ────
                const SliverToBoxAdapter(
                  child: AiCoachSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 6: Meal History ────
                const SliverToBoxAdapter(
                  child: MealHistorySection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 7: Macro Pie Chart ────
                const SliverToBoxAdapter(
                  child: MacroPieChart(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 8: Weekly Calories Chart ────
                const SliverToBoxAdapter(
                  child: WeeklyCaloriesChart(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 9: AI Meal Suggestions ────
                const SliverToBoxAdapter(
                  child: AiMealSuggestionsSection(),
                ),

                // Bottom safe space
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
