import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/glass_text_field.dart';
import '../../../shared/widgets/social_auth_button.dart';

class EmailStep extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onGoogleSignUp;

  const EmailStep({
    super.key,
    required this.controller,
    this.onChanged,
    this.onGoogleSignUp,
  });

  @override
  State<EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<EmailStep> {
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validate);
  }

  void _validate() {
    final valid = Validators.isEmailValid(widget.controller.text);
    if (valid != _isValid) {
      setState(() => _isValid = valid);
    }
  }

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
                Text(AppStrings.emailTitle, style: AppTypography.display.copyWith(color: Colors.white, fontSize: 40)),
                SizedBox(height: 12),
                Text(AppStrings.emailMicrocopy, style: AppTypography.bodyMedium.copyWith(color: context.customColors.grey400)),
                SizedBox(height: 40),
                GlassTextField(
                  hintText: AppStrings.emailHint,
                  controller: widget.controller,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: context.customColors.grey500, size: 20),
                  onChanged: widget.onChanged,
                  suffixIcon: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: widget.controller.text.isNotEmpty ? 1.0 : 0.0,
                    child: Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        _isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _isValid ? context.customColors.success : context.colors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (widget.controller.text.isNotEmpty && !_isValid)
                  Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Enter a valid email address',
                      style: TextStyle(color: context.colors.error.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),

                // ─── Or divider ───
                SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or', style: AppTypography.bodySmall.copyWith(color: context.customColors.grey500)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
                  ],
                ),
                SizedBox(height: 28),

                // ─── Register with Google ───
                SocialAuthButton(
                  label: 'Register with Google',
                  icon: Icons.g_mobiledata_rounded,
                  onPressed: widget.onGoogleSignUp ?? () {},
                ),

                SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
