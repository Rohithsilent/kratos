// lib/features/nutrition/presentation/screens/nutrition_intelligence_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../controllers/nutrition_ws_controller.dart';
import '../widgets/nutrition_score_section.dart';
import '../widgets/hydration_intelligence_section.dart';
import '../widgets/ai_coach_section.dart';
import '../widgets/meal_history_section.dart';
import '../widgets/weekly_meal_report_section.dart';

import '../widgets/log_meal_sheet.dart';

class NutritionIntelligenceScreen extends ConsumerStatefulWidget {
  const NutritionIntelligenceScreen({super.key});

  @override
  ConsumerState<NutritionIntelligenceScreen> createState() =>
      _NutritionIntelligenceScreenState();
}

class _NutritionIntelligenceScreenState
    extends ConsumerState<NutritionIntelligenceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Connect nutrition WebSocket when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nutritionWsProvider.notifier).connect();
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    // Disconnect nutrition WebSocket when screen closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


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

                // ──── Section 2: Hydration Intelligence ────
                const SliverToBoxAdapter(
                  child: HydrationIntelligenceSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 3: AI Nutrition Coach ────
                const SliverToBoxAdapter(
                  child: AiCoachSection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 4: Meal History ────
                const SliverToBoxAdapter(
                  child: MealHistorySection(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ──── Section 5: Weekly Report ────
                const SliverToBoxAdapter(
                  child: WeeklyMealReportSection(),
                ),

                // Bottom safe space for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // ═══ Premium Floating Log Meal Button ═══
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 20,
            right: 20,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _fabController,
                curve: Curves.elasticOut,
              ),
              child: GestureDetector(
                onTap: () => _showLogMealOptions(context),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: context.customColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'LOG MEAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogMealOptions(BuildContext context) {
    LogMealSheet.show(context);
  }
}
