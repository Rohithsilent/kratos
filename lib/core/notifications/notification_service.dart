import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/daily_planner/domain/models/planner_item_model.dart';
import '../../features/workout/domain/models/workout_model.dart';

/// Owns all local notification behavior for Kratos.
///
/// Notification errors are deliberately swallowed. A denied permission or an
/// OEM-specific background restriction must never interrupt a workout.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int workoutNotificationId = 7100;
  static const int streakNotificationId = 7200;
  static const int _plannerIdBase = 10000000;

  static const String _workoutChannelId = 'kratos_live_workout_v1';
  static const String _reminderChannelId = 'kratos_workout_reminders_v1';
  static const String _streakChannelId = 'kratos_streak_guard_v1';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // UTC is a safe fallback. Scheduling still works, though it may not use
      // the device timezone on unusual OEM builds.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_kratos'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      return;
    }

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      // Permission can be requested again later from app settings.
    }
  }

  Future<void> startWorkout({
    required Workout workout,
    required DateTime startedAt,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
  }) async {
    await _ensureInitialized();

    final body = _activeWorkoutBody(
      exerciseName: exerciseName,
      setNumber: setNumber,
      totalSets: totalSets,
    );
    final details = _liveWorkoutDetails(
      when: startedAt,
      isCountdown: false,
      subText: '${workout.exercises.length} exercises • ${workout.split}',
    );

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.startForegroundService(
          id: workoutNotificationId,
          title: '⚡ ${workout.name} in progress',
          body: body,
          notificationDetails: details,
          payload: 'workout:${workout.id}',
          startType: AndroidServiceStartType.startSticky,
          foregroundServiceTypes: const {
            AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
          },
        );
        return;
      }

      // Apple platforms need ActivityKit for a true Live Activity. This
      // fallback still exposes the active session in Notification Center.
      await _plugin.show(
        id: workoutNotificationId,
        title: 'Workout started • ${workout.name}',
        body: body,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentBanner: true,
            presentList: true,
            interruptionLevel: InterruptionLevel.active,
          ),
        ),
        payload: 'workout:${workout.id}',
      );
    } catch (_) {}
  }

  Future<void> showActiveWorkout({
    required Workout workout,
    required DateTime startedAt,
    required String exerciseName,
    required int setNumber,
    required int totalSets,
  }) async {
    await _updateLiveWorkout(
      workout: workout,
      title: '⚡ ${workout.name} in progress',
      body: _activeWorkoutBody(
        exerciseName: exerciseName,
        setNumber: setNumber,
        totalSets: totalSets,
      ),
      details: _liveWorkoutDetails(
        when: startedAt,
        isCountdown: false,
        subText: 'Keep moving • Tap to return',
      ),
    );
  }

  Future<void> showRest({
    required Workout workout,
    required String nextExerciseName,
    required int remainingSeconds,
    required bool isPaused,
  }) async {
    final endTime = DateTime.now().add(Duration(seconds: remainingSeconds));
    await _updateLiveWorkout(
      workout: workout,
      title: isPaused ? 'Rest paused' : 'Recovery mode',
      body: isPaused
          ? '${_formatDuration(remainingSeconds)} remaining • Tap to resume'
          : 'Next: $nextExerciseName • Breathe. Reset. Attack.',
      details: _liveWorkoutDetails(
        when: isPaused ? null : endTime,
        isCountdown: !isPaused,
        subText: '${workout.name} • Rest interval',
      ),
    );
  }

  Future<void> stopWorkout() async {
    await _ensureInitialized();
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.stopForegroundService();
      await _plugin.cancel(id: workoutNotificationId);
    } catch (_) {}
  }

  Future<void> scheduleWorkoutReminder({
    required String date,
    required String workoutName,
  }) async {
    await _ensureInitialized();
    final day = DateTime.tryParse(date);
    if (day == null) return;

    final now = tz.TZDateTime.now(tz.local);
    var delivery = tz.TZDateTime(tz.local, day.year, day.month, day.day, 8);
    final scheduledDay = tz.TZDateTime(tz.local, day.year, day.month, day.day);
    final today = tz.TZDateTime(tz.local, now.year, now.month, now.day);

    if (scheduledDay.isBefore(today)) {
      await cancelWorkoutReminder(date);
      return;
    }
    if (!delivery.isAfter(now)) {
      delivery = now.add(const Duration(seconds: 5));
    }

    try {
      await _plugin.zonedSchedule(
        id: _plannerNotificationId(date),
        title: 'Your arena is ready 🔥',
        body: '$workoutName is on today. Show up for the version of you '
            'that scheduled it.',
        scheduledDate: delivery,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannelId,
            'Workout reminders',
            channelDescription: 'Reminders for workouts scheduled in Kratos',
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
            color: Color(0xFFE50914),
          ),
          iOS: DarwinNotificationDetails(
            presentBanner: true,
            presentList: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
            threadIdentifier: 'kratos_workout_reminders',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'planner:$date',
      );
    } catch (_) {}
  }

  Future<void> cancelWorkoutReminder(String date) async {
    await _ensureInitialized();
    try {
      await _plugin.cancel(id: _plannerNotificationId(date));
    } catch (_) {}
  }

  Future<void> syncScheduledWorkouts(List<PlannerItem> items) async {
    for (final item in items) {
      if (item.workoutId != null &&
          item.workoutName != null &&
          !item.completed) {
        await scheduleWorkoutReminder(
          date: item.date,
          workoutName: item.workoutName!,
        );
      } else {
        await cancelWorkoutReminder(item.date);
      }
    }
  }

  /// Schedules the warning on the evening when skipping the day would break
  /// the current streak. A completed workout moves the warning to tomorrow.
  Future<void> syncStreakWarning(List<WorkoutSession> sessions) async {
    await _ensureInitialized();
    if (sessions.isEmpty) {
      await _cancelStreakWarning();
      return;
    }

    final workoutDays = sessions
        .map((s) => DateTime(
              s.completedAt.year,
              s.completedAt.month,
              s.completedAt.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final latest = workoutDays.first;

    if (latest != todayDate && latest != yesterday) {
      await _cancelStreakWarning();
      return;
    }

    var streak = 1;
    var cursor = latest;
    for (final day in workoutDays.skip(1)) {
      final expected = cursor.subtract(const Duration(days: 1));
      if (day != expected) break;
      streak++;
      cursor = day;
    }

    final warningDay =
        latest == todayDate ? todayDate.add(const Duration(days: 1)) : todayDate;
    final now = tz.TZDateTime.now(tz.local);
    var delivery = tz.TZDateTime(
      tz.local,
      warningDay.year,
      warningDay.month,
      warningDay.day,
      20,
    );
    if (!delivery.isAfter(now)) {
      delivery = now.add(const Duration(seconds: 5));
    }

    try {
      await _plugin.cancel(id: streakNotificationId);
      await _plugin.zonedSchedule(
        id: streakNotificationId,
        title: 'Your $streak-day streak needs you ⚔️',
        body: 'The day is almost over. One workout keeps the chain alive.',
        scheduledDate: delivery,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _streakChannelId,
            'Streak guard',
            channelDescription:
                'A final reminder before an active workout streak expires',
            importance: Importance.high,
            priority: Priority.high,
            visibility: NotificationVisibility.public,
            color: Color(0xFFE50914),
          ),
          iOS: DarwinNotificationDetails(
            presentBanner: true,
            presentList: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
            threadIdentifier: 'kratos_streak_guard',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'streak:danger',
      );
    } catch (_) {}
  }

  AndroidNotificationDetails _liveWorkoutDetails({
    required DateTime? when,
    required bool isCountdown,
    required String subText,
  }) {
    return AndroidNotificationDetails(
      _workoutChannelId,
      'Live workout',
      channelDescription:
          'Persistent workout progress, exercise and rest timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showWhen: when != null,
      when: when?.millisecondsSinceEpoch,
      usesChronometer: when != null,
      chronometerCountDown: isCountdown,
      visibility: NotificationVisibility.public,
      color: const Color(0xFFE50914),
      subText: subText,
    );
  }

  Future<void> _updateLiveWorkout({
    required Workout workout,
    required String title,
    required String body,
    required AndroidNotificationDetails details,
  }) async {
    await _ensureInitialized();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _plugin.show(
        id: workoutNotificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: details),
        payload: 'workout:${workout.id}',
      );
    } catch (_) {}
  }

  Future<void> _cancelStreakWarning() async {
    try {
      await _plugin.cancel(id: streakNotificationId);
    } catch (_) {}
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  int _plannerNotificationId(String date) {
    final compact = int.tryParse(date.replaceAll('-', '')) ?? 0;
    return _plannerIdBase + compact;
  }

  String _activeWorkoutBody({
    required String exerciseName,
    required int setNumber,
    required int totalSets,
  }) {
    return '$exerciseName • Set $setNumber of $totalSets';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}
