import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class HeightRuler extends StatefulWidget {
  final int initialHeight; // always in cm
  final ValueChanged<int> onChanged; // always emits cm
  final int minHeight;
  final int maxHeight;
  final bool useCm;

  const HeightRuler({
    super.key,
    this.initialHeight = 170,
    required this.onChanged,
    this.minHeight = 100,
    this.maxHeight = 220,
    this.useCm = true,
  });

  @override
  State<HeightRuler> createState() => _HeightRulerState();
}

class _HeightRulerState extends State<HeightRuler>
    with SingleTickerProviderStateMixin {
  late FixedExtentScrollController _scrollController;
  late int _selectedHeight;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _selectedHeight = widget.initialHeight;
    _scrollController = FixedExtentScrollController(
      initialItem: widget.maxHeight - widget.initialHeight,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Convert cm to feet and inches
  String _cmToFtIn(int cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    if (inches == 12) {
      return '${feet + 1}′0″';
    }
    return '$feet′$inches″';
  }

  // Get feet value for a cm tick (for ruler labels)
  String? _feetLabel(int cm) {
    final totalInches = cm / 2.54;
    final inches = totalInches % 12;
    // Show label at each foot mark (within ~1 inch tolerance)
    if (inches < 0.5 || inches > 11.5) {
      final feet = (totalInches / 12).round();
      return '$feet ft';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 320,
      child: Row(
        children: [
          // ─── Silhouette + Display ───
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Height value — switches between cm and ft'in"
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: widget.useCm
                      ? Text(
                          '$_selectedHeight',
                          key: ValueKey('cm-$_selectedHeight'),
                          style: AppTypography.metric.copyWith(
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          _cmToFtIn(_selectedHeight),
                          key: ValueKey('ft-$_selectedHeight'),
                          style: AppTypography.metric.copyWith(
                            color: AppColors.white,
                            fontSize: 42,
                          ),
                        ),
                ),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: Text(
                    widget.useCm ? 'cm' : 'ft / in',
                    key: ValueKey(widget.useCm ? 'unit-cm' : 'unit-ft'),
                    style: AppTypography.metricUnit.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Animated silhouette
                AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  height: _mapHeight(_selectedHeight),
                  width: 40,
                  child: CustomPaint(
                    painter: _SilhouettePainter(
                      color: AppColors.primary.withOpacity(0.6),
                    ),
                    size: Size(40, _mapHeight(_selectedHeight)),
                  ),
                ),
              ],
            ),
          ),

          // ─── Ruler ───
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Wheel Picker
                ListWheelScrollView.useDelegate(
                  controller: _scrollController,
                  itemExtent: 16,
                  perspective: 0.002,
                  diameterRatio: 3.0,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedHeight = widget.maxHeight - index;
                    });
                    widget.onChanged(_selectedHeight);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.maxHeight - widget.minHeight + 1,
                    builder: (context, index) {
                      final height = widget.maxHeight - index;
                      final isSelected = height == _selectedHeight;
                      final isMajor = widget.useCm
                          ? height % 10 == 0
                          : _feetLabel(height) != null;
                      final isMid = widget.useCm
                          ? height % 5 == 0
                          : height % 5 == 0;

                      return _RulerTick(
                        value: height,
                        isSelected: isSelected,
                        isMajor: isMajor,
                        isMid: isMid,
                        isDark: isDark,
                        useCm: widget.useCm,
                        feetLabel: widget.useCm ? null : _feetLabel(height),
                      );
                    },
                  ),
                ),

                // Center indicator line
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        height: 2,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withOpacity(
                                0.7 + _pulseController.value * 0.3,
                              ),
                              AppColors.primary,
                              AppColors.primary.withOpacity(
                                0.7 + _pulseController.value * 0.3,
                              ),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _mapHeight(int cm) {
    final normalized = (cm - widget.minHeight) /
        (widget.maxHeight - widget.minHeight);
    return 60 + normalized * 120;
  }
}

class _RulerTick extends StatelessWidget {
  final int value;
  final bool isSelected;
  final bool isMajor;
  final bool isMid;
  final bool isDark;
  final bool useCm;
  final String? feetLabel;

  const _RulerTick({
    required this.value,
    required this.isSelected,
    required this.isMajor,
    required this.isMid,
    required this.isDark,
    this.useCm = true,
    this.feetLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tickWidth = isMajor ? 60.0 : (isMid ? 40.0 : 20.0);
    final showLabel = useCm ? isMajor : feetLabel != null;
    final labelText = useCm ? '$value' : feetLabel ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showLabel)
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text(
              labelText,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.grey500 : AppColors.grey400),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        if (!showLabel) Spacer(),
        Container(
          width: tickWidth,
          height: isMajor ? 2 : 1,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? Colors.white.withOpacity(isMajor ? 0.25 : 0.10)
                    : Colors.black.withOpacity(isMajor ? 0.20 : 0.08)),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final Color color;
  _SilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.08),
        width: w * 0.35,
        height: w * 0.35,
      ),
      paint,
    );

    // Body
    final bodyPath = Path()
      ..moveTo(w * 0.3, h * 0.15)
      ..quadraticBezierTo(w * 0.15, h * 0.35, w * 0.2, h * 0.55)
      ..lineTo(w * 0.35, h * 1.0)
      ..lineTo(w * 0.45, h * 1.0)
      ..lineTo(w * 0.5, h * 0.6)
      ..lineTo(w * 0.55, h * 1.0)
      ..lineTo(w * 0.65, h * 1.0)
      ..lineTo(w * 0.8, h * 0.55)
      ..quadraticBezierTo(w * 0.85, h * 0.35, w * 0.7, h * 0.15)
      ..close();
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
