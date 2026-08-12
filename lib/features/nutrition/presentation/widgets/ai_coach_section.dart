// lib/features/nutrition/presentation/widgets/ai_coach_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_ws_controller.dart';

class AiCoachSection extends ConsumerStatefulWidget {
  const AiCoachSection({super.key});

  @override
  ConsumerState<AiCoachSection> createState() => _AiCoachSectionState();
}

class _AiCoachSectionState extends ConsumerState<AiCoachSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  bool _hasAutoTriggered = false;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(nutritionWsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-trigger analysis when section first builds and WS is connected
    if (!_hasAutoTriggered && wsState.isConnected && wsState.currentInsight.isEmpty && !wsState.isStreaming) {
      _hasAutoTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(nutritionWsProvider.notifier).requestAnalysis();
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A0A2E).withValues(alpha: 0.6),
                  const Color(0xFF0D0D1A).withValues(alpha: 0.8),
                ]
              : [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.04),
                  const Color(0xFF6366F1).withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.15 : 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      const Color(0xFF6366F1).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFA78BFA),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI NUTRITION COACH',
                      style: AppTypography.labelBold.copyWith(
                        color: context.colors.onSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: wsState.isConnected
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          wsState.isStreaming
                              ? 'Thinking...'
                              : (wsState.isConnected ? 'Live' : 'Offline'),
                          style: TextStyle(
                            color: const Color(0xFFA78BFA).withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Refresh button (always visible)
              GestureDetector(
                onTap: () {
                  ref.read(nutritionWsProvider.notifier).requestAnalysis(forceRefresh: true);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.6),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (wsState.isStreaming && wsState.currentInsight.isEmpty)
            _buildLoadingState(context)
          else if (wsState.error != null && wsState.currentInsight.isEmpty)
            _buildErrorState(context, wsState.error!)
          else if (wsState.currentInsight.isNotEmpty)
            _buildStreamingContent(context, wsState)
          else
            _buildEmptyState(context),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: const Color(0xFFA78BFA),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analyzing your nutrition...',
            style: TextStyle(
              color: context.colors.onSurface.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return GestureDetector(
      onTap: () {
        ref.read(nutritionWsProvider.notifier).connect();
        ref.read(nutritionWsProvider.notifier).requestAnalysis();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded,
                color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingContent(BuildContext context, NutritionWsState wsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: wsState.currentInsight,
                        style: TextStyle(
                          color: context.colors.onSurface.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                        ),
                      ),
                      // Blinking cursor while streaming
                      if (wsState.isStreaming)
                        WidgetSpan(
                          child: FadeTransition(
                            opacity: _cursorController,
                            child: Container(
                              width: 2,
                              height: 14,
                              margin: const EdgeInsets.only(left: 2),
                              color: const Color(0xFFA78BFA),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ref.read(nutritionWsProvider.notifier).connect();
        ref.read(nutritionWsProvider.notifier).requestAnalysis();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.onSurface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: const Color(0xFFA78BFA).withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tap to get personalized nutrition insights based on today\'s intake.',
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
