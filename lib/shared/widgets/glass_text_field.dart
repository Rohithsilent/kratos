import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';

class GlassTextField extends StatefulWidget {
  final String hintText;
  final String? labelText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final int maxLines;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const GlassTextField({
    super.key,
    required this.hintText,
    this.labelText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.textInputAction,
    this.maxLines = 1,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusAnim;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusAnim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _focusAnim.forward();
    } else {
      _focusAnim.reverse();
    }
  }

  @override
  void dispose() {
    _focusAnim.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _focusAnim,
      builder: (context, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: _isFocused
              ? AppDecorations.glassInputFocused(context)
              : AppDecorations.glassInput(context),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            style: TextStyle(
              color: isDark ? AppColors.white : AppColors.grey900,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: widget.hintText,
              labelText: widget.labelText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              hintStyle: TextStyle(
                color: isDark ? AppColors.grey500 : AppColors.grey400,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              labelStyle: TextStyle(
                color: _isFocused
                    ? AppColors.primary
                    : (isDark ? AppColors.grey400 : AppColors.grey500),
                fontSize: 14,
              ),
              floatingLabelStyle: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
