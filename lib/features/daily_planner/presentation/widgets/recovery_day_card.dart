// lib/features/daily_planner/presentation/widgets/recovery_day_card.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Simplified recovery card — NO fake metrics (water, sleep, steps removed).
/// Only shows a clean recovery-day indicator with motivational context.
class RecoveryDayCard extends StatelessWidget {
  const RecoveryDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            "TODAY'S MISSION",
            style: AppTypography.labelBold.copyWith(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            borderRadius: 20,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recovery Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(0xFF8B5CF6).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFF8B5CF6).withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.spa_rounded,
                          color: Color(0xFFA78BFA),
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECOVERY DAY',
                            style: TextStyle(
                              color: Color(0xFFA78BFA),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Rest. Repair. Return stronger.',
                            style: TextStyle(color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Divider(color: Colors.white.withOpacity(0.10), height: 1),
                SizedBox(height: 16),

                // Recovery suggestions
                Text(
                  'FOCUS AREAS',
                  style: TextStyle(color: Colors.white.withOpacity(0.25),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFocusChip('Stretching', Icons.self_improvement_rounded),
                    _buildFocusChip('Hydration', Icons.water_drop_rounded),
                    _buildFocusChip('Mobility', Icons.accessibility_new_rounded),
                    _buildFocusChip('Nutrition', Icons.restaurant_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Color(0xFF8B5CF6).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color(0xFF8B5CF6).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFFA78BFA), size: 12),
          SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: Colors.white.withOpacity(0.5),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
