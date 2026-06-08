import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import '../../../core/theme/app_colors.dart';

class DateWheelPicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onChanged;

  const DateWheelPicker({
    super.key,
    this.initialDate,
    required this.onChanged,
  });

  @override
  State<DateWheelPicker> createState() => _DateWheelPickerState();
}

class _DateWheelPickerState extends State<DateWheelPicker> {
  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int get _currentYear => DateTime.now().year;
  int get _minYear => _currentYear - 80;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime(2000, 6, 15);
    _selectedDay = initial.day;
    _selectedMonth = initial.month;
    _selectedYear = initial.year;

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController =
        FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController =
        FixedExtentScrollController(initialItem: _selectedYear - _minYear);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  int _calculateAge() {
    final now = DateTime.now();
    int age = now.year - _selectedYear;
    if (now.month < _selectedMonth ||
        (now.month == _selectedMonth && now.day < _selectedDay)) {
      age--;
    }
    return age.clamp(0, 120);
  }

  void _notifyChange() {
    final maxDay = _daysInMonth(_selectedMonth, _selectedYear);
    if (_selectedDay > maxDay) {
      _selectedDay = maxDay;
    }
    widget.onChanged(DateTime(_selectedYear, _selectedMonth, _selectedDay));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final age = _calculateAge();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Age display
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: RichText(
            key: ValueKey(age),
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$age',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: context.colors.primary,
                    fontFamily: 'BarlowCondensed',
                  ),
                ),
                TextSpan(
                  text: ' years old',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isDark ? context.customColors.grey400 : context.customColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 32),

        // Picker wheels
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection band
              Container(
                height: 44,
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.primary.withOpacity(0.15),
                  ),
                ),
              ),

              Row(
                children: [
                  // Day
                  Expanded(
                    child: _buildWheel(
                      controller: _dayController,
                      itemCount: 31,
                      labelBuilder: (i) => '${i + 1}'.padLeft(2, '0'),
                      onChanged: (i) {
                        setState(() => _selectedDay = i + 1);
                        _notifyChange();
                      },
                      selectedIndex: _selectedDay - 1,
                      isDark: isDark,
                    ),
                  ),
                  // Month
                  Expanded(
                    flex: 2,
                    child: _buildWheel(
                      controller: _monthController,
                      itemCount: 12,
                      labelBuilder: (i) => _months[i],
                      onChanged: (i) {
                        setState(() => _selectedMonth = i + 1);
                        _notifyChange();
                      },
                      selectedIndex: _selectedMonth - 1,
                      isDark: isDark,
                    ),
                  ),
                  // Year
                  Expanded(
                    flex: 2,
                    child: _buildWheel(
                      controller: _yearController,
                      itemCount: _currentYear - _minYear + 1,
                      labelBuilder: (i) => '${_minYear + i}',
                      onChanged: (i) {
                        setState(() => _selectedYear = _minYear + i);
                        _notifyChange();
                      },
                      selectedIndex: _selectedYear - _minYear,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
    required int selectedIndex,
    required bool isDark,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 44,
      perspective: 0.003,
      diameterRatio: 2.0,
      physics: FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          final isSelected = index == selectedIndex;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 20 : 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? (isDark ? Colors.white : context.customColors.grey900)
                    : (isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3)),
              ),
              child: Text(labelBuilder(index)),
            ),
          );
        },
      ),
    );
  }
}
