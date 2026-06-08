import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../widgets/date_wheel_picker.dart';

class DobStep extends StatelessWidget {
  final ValueChanged<DateTime> onChanged;

  const DobStep({super.key, required this.onChanged});

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
                Text(AppStrings.dobTitle, style: AppTypography.display.copyWith(color: Colors.white, fontSize: 40)),
                SizedBox(height: 12),
                Text(AppStrings.dobMicrocopy, style: AppTypography.bodyMedium.copyWith(color: context.customColors.grey400)),
                SizedBox(height: 32),
                DateWheelPicker(onChanged: onChanged),
                SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
