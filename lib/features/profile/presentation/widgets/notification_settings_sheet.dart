import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kratos/core/theme/theme_ext.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../../../core/theme/app_typography.dart';

/// Functional notification settings bottom sheet.
/// Persists toggle states to SharedPreferences.
class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  bool _workoutReminders = true;
  bool _streakAlerts = true;
  bool _plannerNotifs = true;
  bool _loading = true;

  static const _keyWorkout = 'notif_workout_reminders';
  static const _keyStreak = 'notif_streak_alerts';
  static const _keyPlanner = 'notif_planner';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _workoutReminders = prefs.getBool(_keyWorkout) ?? true;
      _streakAlerts = prefs.getBool(_keyStreak) ?? true;
      _plannerNotifs = prefs.getBool(_keyPlanner) ?? true;
      _loading = false;
    });
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: context.glassmorphism.borderColor,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? context.customColors.grey700 : context.customColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_rounded, color: context.colors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                'NOTIFICATIONS',
                style: AppTypography.labelBold.copyWith(
                  color: isDark ? Colors.white : context.customColors.grey900,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: context.colors.primary, strokeWidth: 2),
            )
          else ...[
            _notifToggle(
              context, isDark,
              icon: Icons.fitness_center_rounded,
              title: 'Workout Reminders',
              subtitle: 'Get reminded about scheduled workouts',
              value: _workoutReminders,
              onChanged: (v) {
                setState(() => _workoutReminders = v);
                _saveToggle(_keyWorkout, v);
              },
            ),
            _divider(isDark),
            _notifToggle(
              context, isDark,
              icon: Icons.local_fire_department_rounded,
              title: 'Daily Reminders',
              subtitle: 'Reminds you if you haven\'t worked out today',
              value: _streakAlerts,
              onChanged: (v) {
                setState(() => _streakAlerts = v);
                _saveToggle(_keyStreak, v);
              },
            ),
            _divider(isDark),
            _notifToggle(
              context, isDark,
              icon: Icons.calendar_today_rounded,
              title: 'Planner Updates',
              subtitle: 'Daily planner completion notifications',
              value: _plannerNotifs,
              onChanged: (v) {
                setState(() => _plannerNotifs = v);
                _saveToggle(_keyPlanner, v);
              },
            ),
          ],

          const SizedBox(height: 20),

          // System settings link
          GestureDetector(
            onTap: () async {
              if (Platform.isAndroid) {
                const intent = AndroidIntent(
                  action: 'android.settings.APP_NOTIFICATION_SETTINGS',
                  arguments: <String, dynamic>{
                    'android.provider.extra.APP_PACKAGE': 'com.example.kratos',
                  },
                );
                await intent.launch();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'To fully disable notifications, go to your device\'s app settings.',
                      style: TextStyle(fontSize: 12),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : context.customColors.grey900,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings_rounded, size: 16, color: isDark ? context.customColors.grey500 : context.customColors.grey400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'System notification settings can be managed from your device settings.',
                      style: TextStyle(
                        color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, size: 14, color: isDark ? context.customColors.grey600 : context.customColors.grey300),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifToggle(
    BuildContext context, bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.colors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(
                color: isDark ? Colors.white : context.customColors.grey900,
                fontSize: 14, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(
                color: isDark ? context.customColors.grey500 : context.customColors.grey400,
                fontSize: 11,
              )),
            ]),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: context.colors.primary,
              activeTrackColor: context.colors.primary.withValues(alpha: 0.3),
              inactiveThumbColor: isDark ? context.customColors.grey600 : context.customColors.grey300,
              inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
    indent: 48,
  );
}
