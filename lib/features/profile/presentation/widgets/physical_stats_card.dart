import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_typography.dart';

class PhysicalStatsCard extends StatelessWidget {
  final String height;
  final String weight;
  final String sex;
  final ValueChanged<String> onHeightChanged;
  final ValueChanged<String> onWeightChanged;
  final ValueChanged<String> onSexChanged;

  const PhysicalStatsCard({
    super.key,
    required this.height,
    required this.weight,
    required this.sex,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onSexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: AppDecorations.glassCard(context),
      child: Row(
        children: [
          _buildStatColumn(
            context,
            label: 'HEIGHT',
            value: _parseHeightValue(height),
            unit: _parseHeightUnit(height),
            icon: Icons.straighten_rounded,
            color: const Color(0xFF22D3EE), // cyan
            isDark: isDark,
            onTap: () => _showHeightEditor(context),
          ),
          _buildDivider(isDark),
          _buildStatColumn(
            context,
            label: 'WEIGHT',
            value: _parseWeightValue(weight),
            unit: _parseWeightUnit(weight),
            icon: Icons.fitness_center_rounded,
            color: const Color(0xFFFBBF24), // amber
            isDark: isDark,
            onTap: () => _showWeightEditor(context),
          ),
          _buildDivider(isDark),
          _buildStatColumn(
            context,
            label: 'SEX',
            value: _parseSexDisplay(sex),
            unit: '',
            icon: _sexIcon(sex),
            color: const Color(0xFFA78BFA), // violet
            isDark: isDark,
            onTap: () => _showSexPicker(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.12 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            // Label
            Text(
              label,
              style: AppTypography.labelBold.copyWith(
                color: isDark ? AppColors.grey500 : AppColors.grey400,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            // Value
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.isNotEmpty ? value : '—',
                  style: AppTypography.headlineLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.grey900,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.grey500 : AppColors.grey600,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Edit indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 10,
                    color: isDark ? AppColors.grey500 : AppColors.grey400,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'EDIT',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.grey500 : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 60,
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.06),
    );
  }

  // ─── Parsers ───

  String _parseHeightValue(String h) {
    if (h.isEmpty) return '';
    if (h.toLowerCase().contains('ft') || h.contains("'")) {
      final parts = h.replaceAll('"', '').replaceAll('ft', '').trim();
      return parts;
    }
    final match = RegExp(r'[\d.]+').firstMatch(h);
    return match?.group(0) ?? '';
  }

  String _parseHeightUnit(String h) {
    if (h.isEmpty) return '';
    if (h.toLowerCase().contains('cm')) return 'cm';
    if (h.toLowerCase().contains('ft') || h.contains("'")) return 'ft';
    return 'cm';
  }

  String _parseWeightValue(String w) {
    if (w.isEmpty) return '';
    return RegExp(r'[\d.]+').firstMatch(w)?.group(0) ?? '';
  }

  String _parseWeightUnit(String w) {
    if (w.isEmpty) return '';
    if (w.toLowerCase().contains('lbs')) return 'lbs';
    return 'kg';
  }

  String _parseSexDisplay(String s) {
    if (s.isEmpty) return '—';
    final lower = s.toLowerCase().trim();
    if (lower == 'male' || lower == 'm') return 'M';
    if (lower == 'female' || lower == 'f') return 'F';
    return s.substring(0, 1).toUpperCase();
  }

  IconData _sexIcon(String s) {
    final lower = s.toLowerCase().trim();
    if (lower == 'male' || lower == 'm') return Icons.male_rounded;
    if (lower == 'female' || lower == 'f') return Icons.female_rounded;
    return Icons.transgender_rounded;
  }

  // ─── Editors ───

  void _showHeightEditor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(
      text: RegExp(r'[\d.]+').firstMatch(height)?.group(0) ?? '',
    );
    bool isCm = !height.toLowerCase().contains('ft');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.grey700 : AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'UPDATE HEIGHT',
                      style: AppTypography.labelBold.copyWith(
                        color: isDark ? Colors.white : AppColors.grey900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Unit toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUnitChip(ctx, 'CM', isCm, isDark, () {
                          setSheetState(() => isCm = true);
                        }),
                        const SizedBox(width: 12),
                        _buildUnitChip(ctx, 'FT', !isCm, isDark, () {
                          setSheetState(() => isCm = false);
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Input
                    TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.\x27"]')),
                      ],
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.grey900,
                        fontSize: 32,
                      ),
                      decoration: InputDecoration(
                        hintText: isCm ? '170' : "5'10",
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.grey700 : AppColors.grey300,
                          fontSize: 32,
                        ),
                        suffixText: isCm ? 'cm' : 'ft',
                        suffixStyle: AppTypography.labelBold.copyWith(
                          color: AppColors.grey500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 24),
                    // Save button
                    GestureDetector(
                      onTap: () {
                        final val = controller.text.trim();
                        if (val.isNotEmpty) {
                          final unit = isCm ? 'cm' : 'ft';
                          onHeightChanged('$val $unit');
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'SAVE',
                            style: AppTypography.labelBold.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWeightEditor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(
      text: RegExp(r'[\d.]+').firstMatch(weight)?.group(0) ?? '',
    );
    bool isKg = !weight.toLowerCase().contains('lbs');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.grey700 : AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'UPDATE WEIGHT',
                      style: AppTypography.labelBold.copyWith(
                        color: isDark ? Colors.white : AppColors.grey900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildUnitChip(ctx, 'KG', isKg, isDark, () {
                          setSheetState(() => isKg = true);
                        }),
                        const SizedBox(width: 12),
                        _buildUnitChip(ctx, 'LBS', !isKg, isDark, () {
                          setSheetState(() => isKg = false);
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.grey900,
                        fontSize: 32,
                      ),
                      decoration: InputDecoration(
                        hintText: isKg ? '70' : '154',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.grey700 : AppColors.grey300,
                          fontSize: 32,
                        ),
                        suffixText: isKg ? 'kg' : 'lbs',
                        suffixStyle: AppTypography.labelBold.copyWith(
                          color: AppColors.grey500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        final val = controller.text.trim();
                        if (val.isNotEmpty) {
                          final unit = isKg ? 'kg' : 'lbs';
                          onWeightChanged('$val $unit');
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'SAVE',
                            style: AppTypography.labelBold.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSexPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ['Male', 'Female', 'Other'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey700 : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SELECT SEX',
                style: AppTypography.labelBold.copyWith(
                  color: isDark ? Colors.white : AppColors.grey900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              ...options.map((option) {
                final isSelected = sex.toLowerCase() == option.toLowerCase();
                return GestureDetector(
                  onTap: () {
                    onSexChanged(option);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : (isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.03)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.4)
                            : (isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.06)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option == 'Male'
                              ? Icons.male_rounded
                              : option == 'Female'
                                  ? Icons.female_rounded
                                  : Icons.transgender_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.grey400 : AppColors.grey600),
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          option,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isSelected
                                ? (isDark ? Colors.white : AppColors.grey900)
                                : (isDark
                                    ? AppColors.grey400
                                    : AppColors.grey600),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnitChip(
    BuildContext context,
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.15)
              : (isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelBold.copyWith(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.grey500 : AppColors.grey400),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
