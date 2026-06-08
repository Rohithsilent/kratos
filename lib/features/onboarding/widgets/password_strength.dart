import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = Validators.passwordStrength(password);
    final label = Validators.strengthLabel(strength);
    final color = _strengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                Container(width: double.infinity, color: Colors.white.withOpacity(0.06)),
                AnimatedFractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: strength,
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: Text(
            password.isEmpty ? '' : label,
            key: ValueKey(label),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(height: 12),
        _Requirement(text: 'At least 8 characters', met: password.length >= 8),
        _Requirement(text: 'Contains uppercase letter', met: RegExp(r'[A-Z]').hasMatch(password)),
        _Requirement(text: 'Contains number', met: RegExp(r'[0-9]').hasMatch(password)),
        _Requirement(text: 'Contains special character', met: RegExp(r'[!@#\$%\^&\*]').hasMatch(password)),
      ],
    );
  }

  Color _strengthColor(double strength) {
    if (strength <= 0.25) return AppColors.error;
    if (strength <= 0.50) return AppColors.warning;
    if (strength <= 0.75) return AppColors.info;
    return AppColors.success;
  }
}

class _Requirement extends StatelessWidget {
  final String text;
  final bool met;
  const _Requirement({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? AppColors.success.withOpacity(0.15) : Colors.white.withOpacity(0.04),
              border: Border.all(color: met ? AppColors.success : Colors.white.withOpacity(0.12)),
            ),
            child: met ? Icon(Icons.check, size: 10, color: AppColors.success) : null,
          ),
          SizedBox(width: 8),
          Text(text, style: TextStyle(
            color: met ? AppColors.success.withOpacity(0.9) : Colors.white.withOpacity(0.4),
            fontSize: 12, fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }
}
