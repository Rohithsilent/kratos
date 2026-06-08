import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/glass_text_field.dart';

class PhoneStep extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const PhoneStep({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<PhoneStep> {
  String _selectedCode = '+91';
  String _selectedFlag = '🇮🇳';
  bool _showPicker = false;

  static final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'United States'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
    {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+81', 'flag': '🇯🇵', 'name': 'Japan'},
    {'code': '+86', 'flag': '🇨🇳', 'name': 'China'},
    {'code': '+82', 'flag': '🇰🇷', 'name': 'South Korea'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brazil'},
    {'code': '+7', 'flag': '🇷🇺', 'name': 'Russia'},
    {'code': '+27', 'flag': '🇿🇦', 'name': 'South Africa'},
  ];

  int get _digitCount {
    return widget.controller.text.replaceAll(RegExp(r'\D'), '').length;
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
                Text(AppStrings.phoneTitle, style: AppTypography.display.copyWith(color: Colors.white, fontSize: 40)),
                SizedBox(height: 12),
                Text(AppStrings.phoneMicrocopy, style: AppTypography.bodyMedium.copyWith(color: context.customColors.grey400)),
                SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country code selector
                    GestureDetector(
                      onTap: () => setState(() => _showPicker = !_showPicker),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 17),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedFlag, style: TextStyle(fontSize: 20)),
                            SizedBox(width: 6),
                            Text(_selectedCode, style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                            SizedBox(width: 2),
                            Icon(
                              _showPicker ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: context.customColors.grey500, size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassTextField(
                            hintText: AppStrings.phoneHint,
                            controller: widget.controller,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onChanged: widget.onChanged,
                            suffixIcon: AnimatedOpacity(
                              duration: Duration(milliseconds: 300),
                              opacity: widget.controller.text.isNotEmpty ? 1.0 : 0.0,
                              child: Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  _digitCount == 10
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _digitCount == 10
                                      ? context.customColors.success
                                      : context.colors.error,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          if (widget.controller.text.isNotEmpty && _digitCount != 10)
                            Padding(
                              padding: EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                '$_digitCount/10 digits',
                                style: TextStyle(
                                  color: _digitCount < 10 ? context.customColors.grey500 : context.customColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Country code dropdown
                AnimatedCrossFade(
                  duration: Duration(milliseconds: 250),
                  crossFadeState: _showPicker ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: SizedBox.shrink(),
                  secondChild: Container(
                    margin: EdgeInsets.only(top: 12),
                    constraints: BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _countryCodes.length,
                        itemBuilder: (context, index) {
                          final country = _countryCodes[index];
                          final isSelected = country['code'] == _selectedCode;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCode = country['code']!;
                                _selectedFlag = country['flag']!;
                                _showPicker = false;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              color: isSelected ? context.colors.primary.withOpacity(0.08) : Colors.transparent,
                              child: Row(
                                children: [
                                  Text(country['flag']!, style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 10),
                                  Text(country['code']!, style: TextStyle(
                                    color: isSelected ? context.colors.primary : Colors.white,
                                    fontWeight: FontWeight.w600, fontSize: 14,
                                  )),
                                  SizedBox(width: 10),
                                  Expanded(child: Text(country['name']!, style: TextStyle(
                                    color: context.customColors.grey400, fontSize: 13,
                                  ))),
                                  if (isSelected) Icon(Icons.check_rounded, color: context.colors.primary, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
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
