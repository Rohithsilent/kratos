// lib/features/nutrition/presentation/widgets/food_scanner_sheet.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/nutrition_workflow_controller.dart';
import '../controllers/nutrition_ws_controller.dart';

class FoodScannerSheet extends ConsumerStatefulWidget {
  const FoodScannerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FoodScannerSheet(),
    );
  }

  @override
  ConsumerState<FoodScannerSheet> createState() => _FoodScannerSheetState();
}

class _FoodScannerSheetState extends ConsumerState<FoodScannerSheet> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealScanProvider.notifier).reset();
      ref.read(nutritionWsProvider.notifier).clearFitCheck();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBytes = bytes);
    ref.read(mealScanProvider.notifier).scanImage(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(mealScanProvider);
    final wsState = ref.watch(nutritionWsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    // Auto-trigger fit check when scan result arrives
    if (scanState.scanResult != null && wsState.fitCheckResult == null && !wsState.isStreaming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(nutritionWsProvider.notifier).requestFitCheck(scanState.scanResult!);
      });
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: context.colors.onSurface.withValues(alpha: 0.06))),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: bottomPad + 24),
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
                    colors: [
                      context.colors.primary.withValues(alpha: 0.15),
                      context.colors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.document_scanner_rounded, color: context.colors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI FOOD SCANNER', style: AppTypography.labelBold.copyWith(color: context.colors.onSurface, fontSize: 14, letterSpacing: 1.0)),
                const SizedBox(height: 2),
                Text('Scan · Analyze · Log', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.35), fontSize: 11, fontWeight: FontWeight.w500)),
              ]),
            ]),
            const SizedBox(height: 24),

            // Image source buttons (show only if no image yet)
            if (_imageBytes == null && !scanState.isScanning) ...[
              Row(children: [
                Expanded(child: _SourceButton(icon: Icons.camera_alt_rounded, label: 'CAMERA', onTap: () => _pickImage(ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(child: _SourceButton(icon: Icons.photo_library_rounded, label: 'GALLERY', onTap: () => _pickImage(ImageSource.gallery))),
              ]),
            ],

            // Scanning state — shimmer loading
            if (scanState.isScanning) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.onSurface.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(children: [
                  if (_imageBytes != null) ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover)),
                  const SizedBox(height: 16),
                  // Shimmer-like loading bars
                  ..._buildShimmerBars(context, isDark),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: context.colors.primary, strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text('Identifying food with AI...', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
            ],

            // Error state
            if (scanState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.1)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(scanState.error!, style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600))),
                ]),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  setState(() => _imageBytes = null);
                  ref.read(mealScanProvider.notifier).reset();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('TRY AGAIN', style: TextStyle(color: context.colors.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ),
            ],

            // Result state
            if (scanState.scanResult != null) ...[
              const SizedBox(height: 16),
              _buildResultCard(context, scanState, isDark),
              const SizedBox(height: 12),

              // Fit Check section
              _buildFitCheck(context, wsState, isDark),
              const SizedBox(height: 16),

              // Action buttons
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _imageBytes = null);
                      ref.read(mealScanProvider.notifier).reset();
                      ref.read(nutritionWsProvider.notifier).clearFitCheck();
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: context.colors.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.06)),
                      ),
                      child: Center(child: Text('DISCARD', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () async {
                      final foodName = scanState.scanResult?['foodName'] as String? ?? 'meal';
                      await ref.read(mealScanProvider.notifier).confirmAndLog();
                      if (context.mounted) {
                        // Trigger proactive insight
                        ref.read(nutritionWsProvider.notifier).notifyMealLogged(foodName);
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(gradient: context.customColors.primaryGradient, borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: context.colors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Center(child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('ADD TO LOG', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      )),
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, MealScanState scanState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_imageBytes != null) ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!, height: 140, width: double.infinity, fit: BoxFit.cover)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                scanState.scanResult!['foodName'] as String? ?? 'Unknown',
                style: TextStyle(color: context.colors.onSurface, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          _MacroPill(label: 'Cal', value: '${(scanState.scanResult!['calories'] as num?)?.round() ?? 0}', unit: 'kcal', color: context.colors.primary),
          const SizedBox(width: 6),
          _MacroPill(label: 'Protein', value: '${(scanState.scanResult!['protein'] as num?)?.round() ?? 0}', unit: 'g', color: const Color(0xFFFF6B6B)),
          const SizedBox(width: 6),
          _MacroPill(label: 'Carbs', value: '${(scanState.scanResult!['carbs'] as num?)?.round() ?? 0}', unit: 'g', color: const Color(0xFFFFB852)),
          const SizedBox(width: 6),
          _MacroPill(label: 'Fats', value: '${(scanState.scanResult!['fats'] as num?)?.round() ?? 0}', unit: 'g', color: const Color(0xFF52D8FF)),
        ]),
      ]),
    );
  }

  Widget _buildFitCheck(BuildContext context, NutritionWsState wsState, bool isDark) {
    if (wsState.fitCheckResult == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.onSurface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: context.colors.primary.withValues(alpha: 0.3), strokeWidth: 2)),
          const SizedBox(width: 10),
          Text('Checking impact on your daily targets...', style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    final percentages = wsState.fitCheckResult!['percentages'] as Map<String, dynamic>? ?? {};
    final warnings = (wsState.fitCheckResult!['warnings'] as List<dynamic>?) ?? [];
    final verdict = wsState.fitCheckResult!['verdict'] as String? ?? '';
    final calPct = percentages['calories'] ?? 0;

    final hasWarnings = warnings.isNotEmpty;
    final accentColor = hasWarnings ? const Color(0xFFFFB852) : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              hasWarnings ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: accentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'FIT CHECK',
              style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
            const Spacer(),
            Text(
              '$calPct% of daily calories',
              style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (calPct / 100.0).clamp(0.0, 1.0),
              backgroundColor: context.colors.onSurface.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation(accentColor),
              minHeight: 4,
            ),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                w as String,
                style: TextStyle(color: const Color(0xFFFFB852), fontSize: 10, fontWeight: FontWeight.w600),
              ),
            )),
          ],
          const SizedBox(height: 6),
          Text(verdict, style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Widget> _buildShimmerBars(BuildContext context, bool isDark) {
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.04);
    return [
      Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(7))),
      const SizedBox(height: 8),
      Container(height: 14, width: 200, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(7))),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Container(height: 40, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(10)))),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 40, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(10)))),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 40, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(10)))),
      ]),
    ];
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: context.colors.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: context.colors.primary, size: 28),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: context.colors.onSurface.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _MacroPill({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(unit, style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
