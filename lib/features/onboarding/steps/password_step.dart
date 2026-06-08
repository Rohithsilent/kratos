import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_text_field.dart';
import '../widgets/password_strength.dart';

class PasswordStep extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController confirmController;

  const PasswordStep({super.key, required this.controller, required this.confirmController});

  @override
  State<PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<PasswordStep> {
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(AppStrings.passwordTitle, style: AppTypography.display.copyWith(color: AppColors.white, fontSize: 40)),
            SizedBox(height: 12),
            Text(AppStrings.passwordMicrocopy, style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
            SizedBox(height: 36),
            GlassTextField(
              hintText: AppStrings.passwordHint,
              controller: widget.controller,
              obscureText: _obscure1,
              prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.grey500, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.grey500, size: 20),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 16),
            GlassTextField(
              hintText: AppStrings.confirmPasswordHint,
              controller: widget.confirmController,
              obscureText: _obscure2,
              prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.grey500, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.grey500, size: 20),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
            PasswordStrengthIndicator(password: widget.controller.text),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
