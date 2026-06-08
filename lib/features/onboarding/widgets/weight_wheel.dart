import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class WeightWheel extends StatefulWidget {
  final double initialWeight; // always in kg
  final ValueChanged<double> onChanged; // always emits kg
  final bool useKg;

  const WeightWheel({
    super.key,
    this.initialWeight = 70.0,
    required this.onChanged,
    this.useKg = true,
  });

  @override
  State<WeightWheel> createState() => _WeightWheelState();
}

class _WeightWheelState extends State<WeightWheel> {
  late FixedExtentScrollController _scrollController;
  late double _selectedWeight; // always stored in kg

  // KG config
  static final double _minKg = 30.0;
  static final double _maxKg = 200.0;
  static final double _stepKg = 0.5;

  // LBS config
  static final double _minLbs = 66.0;
  static final double _maxLbs = 440.0;
  static final double _stepLbs = 1.0;

  double get _minWeight => widget.useKg ? _minKg : _minLbs;
  double get _maxWeight => widget.useKg ? _maxKg : _maxLbs;
  double get _step => widget.useKg ? _stepKg : _stepLbs;

  int get _itemCount =>
      ((_maxWeight - _minWeight) / _step).round() + 1;

  double _kgToLbs(double kg) => kg * 2.20462;
  double _lbsToKg(double lbs) => lbs / 2.20462;

  /// The display value (in whichever unit is active)
  double get _displayValue {
    if (widget.useKg) return _selectedWeight;
    return _kgToLbs(_selectedWeight);
  }

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.initialWeight;
    _scrollController = FixedExtentScrollController(
      initialItem: _valueToIndex(_selectedWeight),
    );
  }

  /// Compute scroll index from a kg value
  int _valueToIndex(double kg) {
    if (widget.useKg) {
      return ((kg - _minKg) / _stepKg).round();
    } else {
      final lbs = _kgToLbs(kg);
      return ((lbs - _minLbs) / _stepLbs).round().clamp(0, _itemCount - 1);
    }
  }

  @override
  void didUpdateWidget(covariant WeightWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useKg != widget.useKg) {
      // Unit toggled — jump scroll to the equivalent position
      final newIndex = _valueToIndex(_selectedWeight);
      _scrollController.dispose();
      _scrollController = FixedExtentScrollController(initialItem: newIndex);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── Weight Display ───
        AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: Text(
            widget.useKg
                ? _displayValue.toStringAsFixed(1)
                : _displayValue.round().toString(),
            key: ValueKey('${widget.useKg}-$_selectedWeight'),
            style: AppTypography.metric.copyWith(
              color: Colors.white,
              fontSize: 72,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: Text(
            widget.useKg ? 'kg' : 'lbs',
            key: ValueKey(widget.useKg ? 'u-kg' : 'u-lbs'),
            style: AppTypography.metricUnit.copyWith(
              color: context.customColors.grey400,
            ),
          ),
        ),

        SizedBox(height: 32),

        // ─── Wheel Picker ───
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection highlight
              Container(
                height: 52,
                margin: EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.colors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),

              // Wheel
              ListWheelScrollView.useDelegate(
                key: ValueKey(widget.useKg), // forces rebuild on unit toggle
                controller: _scrollController,
                itemExtent: 52,
                perspective: 0.003,
                diameterRatio: 2.5,
                physics: FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  final rawValue = _minWeight + index * _step;
                  setState(() {
                    if (widget.useKg) {
                      _selectedWeight = rawValue;
                    } else {
                      // Convert lbs back to kg for storage
                      _selectedWeight = _lbsToKg(rawValue);
                    }
                  });
                  widget.onChanged(_selectedWeight); // always emits kg
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: _itemCount,
                  builder: (context, index) {
                    final displayVal = _minWeight + index * _step;
                    final isSelected = index == _valueToIndex(_selectedWeight);
                    final isWhole = displayVal == displayVal.roundToDouble();

                    return Center(
                      child: AnimatedDefaultTextStyle(
                        duration: Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isSelected ? 24 : (isWhole ? 18 : 16),
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : (isWhole
                                  ? FontWeight.w600
                                  : FontWeight.w400),
                          color: isSelected
                              ? context.colors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(
                                      isWhole ? 0.5 : 0.25)
                                  : Colors.black.withOpacity(
                                      isWhole ? 0.5 : 0.25)),
                        ),
                        child: Text(
                          widget.useKg
                              ? displayVal.toStringAsFixed(1)
                              : displayVal.round().toString(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
