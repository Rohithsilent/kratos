import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_text_field.dart';

class NameStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const NameStep({super.key, required this.controller, required this.onNext});

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
                Text(AppStrings.nameTitle, style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 40)),
                SizedBox(height: 12),
                Text(AppStrings.nameMicrocopy, style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
                SizedBox(height: 40),
                GlassTextField(
                  hintText: AppStrings.nameHint,
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.grey500, size: 20),
                  onChanged: (_) => onNext(),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
