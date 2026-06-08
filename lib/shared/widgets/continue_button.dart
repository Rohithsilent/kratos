import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ContinueButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;
  final bool isLoading;
  final IconData? icon;

  const ContinueButton({
    super.key,
    this.text = 'Continue',
    required this.onPressed,
    this.isEnabled = true,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<ContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowOpacity = widget.isEnabled
            ? 0.2 + _glowController.value * 0.15
            : 0.0;

        return AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: widget.isEnabled ? 1.0 : 0.5,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: widget.isEnabled
                  ? context.customColors.primaryGradient
                  : LinearGradient(
                      colors: [context.customColors.grey700, context.customColors.grey800],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isEnabled
                  ? [
                      BoxShadow(
                        color: context.colors.primary.withOpacity(glowOpacity),
                        blurRadius: 28,
                        offset: Offset(0, 8),
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isEnabled && !widget.isLoading
                    ? widget.onPressed
                    : null,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.1),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.text,
                              style: AppTypography.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            if (widget.icon != null) ...[
                              SizedBox(width: 8),
                              Icon(widget.icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : context.customColors.grey900, size: 20),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
