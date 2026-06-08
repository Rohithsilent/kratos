import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../widgets/height_ruler.dart';

class HeightStep extends StatefulWidget {
  final ValueChanged<int> onChanged;

  const HeightStep({super.key, required this.onChanged});

  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  bool _useCm = true;

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
                Text(AppStrings.heightTitle, style: AppTypography.display.copyWith(color: Colors.white, fontSize: 40)),
                SizedBox(height: 12),
                Text(AppStrings.heightMicrocopy, style: AppTypography.bodyMedium.copyWith(color: context.customColors.grey400)),
                SizedBox(height: 20),

                // CM / FT toggle
                Center(
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToggleChip(label: 'CM', isActive: _useCm, onTap: () => setState(() => _useCm = true)),
                        _ToggleChip(label: 'FT', isActive: !_useCm, onTap: () => setState(() => _useCm = false)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),
                HeightRuler(onChanged: widget.onChanged, useCm: _useCm),
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
        decoration: BoxDecoration(
          color: isActive ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: AppTypography.labelBold.copyWith(
          color: isActive ? Colors.white : context.customColors.grey500,
          fontSize: 13,
        )),
      ),
    );
  }
}
