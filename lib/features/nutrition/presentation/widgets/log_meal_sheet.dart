// lib/features/nutrition/presentation/widgets/log_meal_sheet.dart

import 'package:flutter/material.dart';

import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import 'food_scanner_sheet.dart';
import 'manual_meal_sheet.dart';

class LogMealSheet extends StatelessWidget {
  const LogMealSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogMealSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: bottomPad + 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: context.colors.onSurface.withValues(alpha: 0.06))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.15),
                    context.colors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.restaurant_rounded, color: context.colors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LOG A MEAL', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface, fontSize: 16, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text('Choose how you want to log', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ]),
          const SizedBox(height: 24),

          // Options
          _OptionTile(
            icon: Icons.document_scanner_rounded,
            title: 'AI Food Scanner',
            subtitle: 'Take a photo and let AI identify it',
            gradient: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              const Color(0xFF6366F1).withValues(alpha: 0.05),
            ],
            iconColor: const Color(0xFFA78BFA),
            onTap: () {
              Navigator.pop(context);
              FoodScannerSheet.show(context);
            },
          ),
          const SizedBox(height: 10),

          _OptionTile(
            icon: Icons.edit_note_rounded,
            title: 'Manual Entry',
            subtitle: 'Type in food name and macros',
            gradient: [
              const Color(0xFF22C55E).withValues(alpha: 0.12),
              const Color(0xFF16A34A).withValues(alpha: 0.05),
            ],
            iconColor: const Color(0xFF22C55E),
            onTap: () {
              Navigator.pop(context);
              ManualMealSheet.show(context);
            },
          ),

        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color iconColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: context.colors.onSurface, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.onSurface.withValues(alpha: 0.2), size: 20),
          ],
        ),
      ),
    );
  }
}
