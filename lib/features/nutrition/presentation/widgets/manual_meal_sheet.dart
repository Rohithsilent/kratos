// lib/features/nutrition/presentation/widgets/manual_meal_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_workflow_controller.dart';
import '../controllers/nutrition_ws_controller.dart';

class ManualMealSheet extends ConsumerStatefulWidget {
  final bool quickAdd;
  const ManualMealSheet({super.key, this.quickAdd = false});

  static Future<void> show(BuildContext context, {bool quickAdd = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualMealSheet(quickAdd: quickAdd),
    );
  }

  @override
  ConsumerState<ManualMealSheet> createState() => _ManualMealSheetState();
}

class _ManualMealSheetState extends ConsumerState<ManualMealSheet> {
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  bool _isLogging = false;

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  Future<void> _logMeal() async {
    final foodName = widget.quickAdd
        ? 'Quick Add'
        : _foodNameController.text.trim();
    final calories = double.tryParse(_caloriesController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fats = double.tryParse(_fatsController.text) ?? 0;

    if (calories == 0 && protein == 0 && carbs == 0 && fats == 0) return;
    if (foodName.isEmpty && !widget.quickAdd) return;

    setState(() => _isLogging = true);

    await ref.read(manualMealProvider.notifier).logMeal(
      foodName: foodName.isEmpty ? 'Quick Add' : foodName,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );

    // Trigger proactive insight
    ref.read(nutritionWsProvider.notifier).notifyMealLogged(foodName.isEmpty ? 'Quick Add' : foodName);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: bottomPad + 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: context.colors.onSurface.withValues(alpha: 0.06))),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.quickAdd
                        ? [
                            const Color(0xFFFFB852).withValues(alpha: 0.15),
                            const Color(0xFFF59E0B).withValues(alpha: 0.05),
                          ]
                        : [
                            const Color(0xFF22C55E).withValues(alpha: 0.15),
                            const Color(0xFF16A34A).withValues(alpha: 0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.quickAdd ? Icons.bolt_rounded : Icons.edit_note_rounded,
                  color: widget.quickAdd ? const Color(0xFFFFB852) : const Color(0xFF22C55E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  widget.quickAdd ? 'QUICK ADD' : 'MANUAL ENTRY',
                  style: AppTypography.labelBold.copyWith(color: context.colors.onSurface, fontSize: 16, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.quickAdd ? 'Just enter calories and macros' : 'Enter food details',
                  style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ]),
            ]),
            const SizedBox(height: 24),

            // Food Name (hidden in Quick Add mode)
            if (!widget.quickAdd) ...[
              _InputField(
                controller: _foodNameController,
                label: 'FOOD NAME',
                hint: 'e.g., Grilled Chicken Breast',
                icon: Icons.restaurant_rounded,
                accentColor: context.colors.primary,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 14),
            ],

            // Macro inputs
            Row(children: [
              Expanded(child: _InputField(
                controller: _caloriesController,
                label: 'CALORIES',
                hint: '0',
                icon: Icons.local_fire_department_rounded,
                accentColor: context.colors.primary,
              )),
              const SizedBox(width: 10),
              Expanded(child: _InputField(
                controller: _proteinController,
                label: 'PROTEIN (g)',
                hint: '0',
                icon: Icons.fitness_center_rounded,
                accentColor: const Color(0xFFFF6B6B),
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _InputField(
                controller: _carbsController,
                label: 'CARBS (g)',
                hint: '0',
                icon: Icons.grain_rounded,
                accentColor: const Color(0xFFFFB852),
              )),
              const SizedBox(width: 10),
              Expanded(child: _InputField(
                controller: _fatsController,
                label: 'FATS (g)',
                hint: '0',
                icon: Icons.water_drop_rounded,
                accentColor: const Color(0xFF52D8FF),
              )),
            ]),
            const SizedBox(height: 24),

            // Submit button
            GestureDetector(
              onTap: _isLogging ? null : _logMeal,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: context.customColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLogging
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              widget.quickAdd ? 'QUICK ADD' : 'LOG MEAL',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isNumeric = keyboardType == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: accentColor.withValues(alpha: 0.5), size: 12),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.35),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          TextField(
            controller: controller,
            keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : keyboardType,
            inputFormatters: isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))] : null,
            style: TextStyle(
              color: context.colors.onSurface.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: context.colors.onSurface.withValues(alpha: 0.15),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}
