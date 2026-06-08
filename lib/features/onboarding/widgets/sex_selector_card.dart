import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SexSelectorCard extends StatelessWidget {
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const SexSelectorCard({
    super.key,
    this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Option(label: 'Male', icon: Icons.male_rounded, isSelected: selectedValue == 'Male', onTap: () => onSelected('Male'))),
        SizedBox(width: 12),
        Expanded(child: _Option(label: 'Female', icon: Icons.female_rounded, isSelected: selectedValue == 'Female', onTap: () => onSelected('Female'))),
        SizedBox(width: 12),
        Expanded(child: _Option(label: 'Other', icon: Icons.transgender_rounded, isSelected: selectedValue == 'Other', onTap: () => onSelected('Other'))),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _Option({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 140,
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary.withOpacity(0.10) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.colors.primary.withOpacity(0.6) : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: context.colors.primary.withOpacity(0.15), blurRadius: 24, spreadRadius: -4)] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? context.colors.primary.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
              ),
              child: Icon(icon, size: 28, color: isSelected ? context.colors.primary : (isDark ? context.customColors.grey400 : context.customColors.grey500)),
            ),
            SizedBox(height: 10),
            Text(label, style: AppTypography.labelMedium.copyWith(
              color: isSelected ? (isDark ? Colors.white : context.customColors.grey900) : (isDark ? context.customColors.grey400 : context.customColors.grey500),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}
