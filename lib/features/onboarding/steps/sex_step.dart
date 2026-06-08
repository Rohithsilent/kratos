import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../widgets/sex_selector_card.dart';

class SexStep extends StatelessWidget {
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const SexStep({super.key, this.selectedValue, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 24),
                Text(AppStrings.sexTitle, style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 40)),
                SizedBox(height: 12),
                Text(AppStrings.sexMicrocopy, style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
                SizedBox(height: 40),
                SexSelectorCard(selectedValue: selectedValue, onSelected: onSelected),
                SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
