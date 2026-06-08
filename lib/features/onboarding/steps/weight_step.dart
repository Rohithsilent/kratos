import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../widgets/weight_wheel.dart';

class WeightStep extends StatefulWidget {
  final ValueChanged<double> onChanged;

  const WeightStep({super.key, required this.onChanged});

  @override
  State<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<WeightStep> {
  bool _useKg = true;

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
                Text(AppStrings.weightTitle, style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 40)),
                SizedBox(height: 12),
                Text(AppStrings.weightMicrocopy, style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
                SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToggleChip(label: 'KG', isActive: _useKg, onTap: () => setState(() => _useKg = true)),
                        _ToggleChip(label: 'LBS', isActive: !_useKg, onTap: () => setState(() => _useKg = false)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                WeightWheel(onChanged: widget.onChanged, useKg: _useKg),
                SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: AppTypography.labelBold.copyWith(color: isActive ? AppColors.white : AppColors.grey500, fontSize: 13)),
      ),
    );
  }
}
