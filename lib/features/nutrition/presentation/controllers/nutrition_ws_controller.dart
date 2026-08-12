import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../daily_planner/presentation/controllers/nutrition_controller.dart';
import '../../../daily_planner/presentation/controllers/hydration_controller.dart';
import '../../../daily_planner/utils/planner_helpers.dart';

class NutritionWsState {
  final bool isConnected;
  final bool isStreaming;
  final String currentInsight;
  final Map<String, dynamic>? fitCheckResult;
  final String? error;

  const NutritionWsState({
    this.isConnected = false,
    this.isStreaming = false,
    this.currentInsight = '',
    this.fitCheckResult,
    this.error,
  });

  NutritionWsState copyWith({
    bool? isConnected,
    bool? isStreaming,
    String? currentInsight,
    Map<String, dynamic>? fitCheckResult,
    String? error,
  }) {
    return NutritionWsState(
      isConnected: isConnected ?? this.isConnected,
      isStreaming: isStreaming ?? this.isStreaming,
      currentInsight: currentInsight ?? this.currentInsight,
      fitCheckResult: fitCheckResult ?? this.fitCheckResult,
      error: error,
    );
  }
}

class NutritionWsNotifier extends Notifier<NutritionWsState> {
  WebSocketChannel? _channel;

  String get _userId {
    return ref.read(firebaseAuthProvider).currentUser?.uid ?? 'guest';
  }

  @override
  NutritionWsState build() {
    ref.onDispose(() {
      _channel?.sink.close();
    });
    return const NutritionWsState();
  }

  void connect() {
    if (_channel != null) return; // Already connected

    try {
      const wsHost = '10.252.42.49:8000';
      final wsUrl = 'ws://$wsHost/ws/nutrition/$_userId';
      debugPrint('[NutritionWS] Connecting to $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      state = state.copyWith(isConnected: true, error: null);

      _channel!.stream.listen(
        (data) => _handleMessage(data),
        onError: (err) {
          debugPrint('[NutritionWS] Error: $err');
          state = state.copyWith(isConnected: false, isStreaming: false, error: 'Connection lost');
          _channel = null;
        },
        onDone: () {
          debugPrint('[NutritionWS] Disconnected');
          state = state.copyWith(isConnected: false, isStreaming: false);
          _channel = null;
        },
      );
    } catch (e) {
      debugPrint('[NutritionWS] Connect failed: $e');
      state = state.copyWith(isConnected: false, error: e.toString());
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    state = state.copyWith(isConnected: false, isStreaming: false);
  }

  void _handleMessage(dynamic data) {
    try {
      final payload = jsonDecode(data as String);
      final type = payload['type'];

      if (type == 'stream_start') {
        state = state.copyWith(isStreaming: true, currentInsight: '');
      } else if (type == 'stream_chunk') {
        final chunk = payload['content'] as String;
        state = state.copyWith(
          currentInsight: state.currentInsight + chunk,
        );
      } else if (type == 'stream_end') {
        state = state.copyWith(isStreaming: false);
      } else if (type == 'cached_insight') {
        state = state.copyWith(
          currentInsight: payload['content'] as String,
          isStreaming: false,
        );
      } else if (type == 'fit_check_result') {
        state = state.copyWith(
          fitCheckResult: payload as Map<String, dynamic>,
        );
      } else if (type == 'error') {
        state = state.copyWith(error: payload['content']);
      }
    } catch (e) {
      debugPrint('[NutritionWS] Handle error: $e');
    }
  }

  /// Request AI coach analysis
  void requestAnalysis({bool forceRefresh = false}) {
    if (_channel == null) connect();
    if (_channel == null) return;

    final nutrition = ref.read(todayNutritionProvider);
    final hydration = ref.read(todayHydrationProvider);
    final today = PlannerHelpers.formatDate(DateTime.now());

    _channel!.sink.add(jsonEncode({
      'type': 'analyze',
      'date': today,
      'force_refresh': forceRefresh,
      'intake': {
        'calories': nutrition.caloriesConsumed,
        'protein_g': nutrition.proteinConsumed,
        'carbs_g': nutrition.carbsConsumed,
        'fats_g': nutrition.fatsConsumed,
        'water_ml': hydration.waterConsumed,
      },
      'targets': {
        'calories': nutrition.caloriesTarget,
        'protein_g': nutrition.proteinTarget,
        'carbs_g': nutrition.carbsTarget,
        'fats_g': nutrition.fatsTarget,
        'water_ml': hydration.waterTarget,
      },
    }));
  }

  /// Request fit check for a scanned food before logging
  void requestFitCheck(Map<String, dynamic> scannedFood) {
    if (_channel == null) connect();
    if (_channel == null) return;

    // Clear previous fit check
    state = NutritionWsState(
      isConnected: state.isConnected,
      isStreaming: state.isStreaming,
      currentInsight: state.currentInsight,
      fitCheckResult: null,
      error: state.error,
    );

    final nutrition = ref.read(todayNutritionProvider);
    final hydration = ref.read(todayHydrationProvider);

    _channel!.sink.add(jsonEncode({
      'type': 'fit_check',
      'food': scannedFood,
      'intake': {
        'calories': nutrition.caloriesConsumed,
        'protein_g': nutrition.proteinConsumed,
        'carbs_g': nutrition.carbsConsumed,
        'fats_g': nutrition.fatsConsumed,
        'water_ml': hydration.waterConsumed,
      },
      'targets': {
        'calories': nutrition.caloriesTarget,
        'protein_g': nutrition.proteinTarget,
        'carbs_g': nutrition.carbsTarget,
        'fats_g': nutrition.fatsTarget,
        'water_ml': hydration.waterTarget,
      },
    }));
  }

  /// Notify backend after a meal is logged for proactive insight
  void notifyMealLogged(String foodName) {
    if (_channel == null) return;

    final nutrition = ref.read(todayNutritionProvider);
    final hydration = ref.read(todayHydrationProvider);
    final today = PlannerHelpers.formatDate(DateTime.now());

    _channel!.sink.add(jsonEncode({
      'type': 'meal_logged',
      'date': today,
      'food_name': foodName,
      'intake': {
        'calories': nutrition.caloriesConsumed,
        'protein_g': nutrition.proteinConsumed,
        'carbs_g': nutrition.carbsConsumed,
        'fats_g': nutrition.fatsConsumed,
        'water_ml': hydration.waterConsumed,
      },
      'targets': {
        'calories': nutrition.caloriesTarget,
        'protein_g': nutrition.proteinTarget,
        'carbs_g': nutrition.carbsTarget,
        'fats_g': nutrition.fatsTarget,
        'water_ml': hydration.waterTarget,
      },
    }));
  }

  /// Clear fit check result
  void clearFitCheck() {
    state = NutritionWsState(
      isConnected: state.isConnected,
      isStreaming: state.isStreaming,
      currentInsight: state.currentInsight,
      fitCheckResult: null,
      error: state.error,
    );
  }
}

final nutritionWsProvider = NotifierProvider<NutritionWsNotifier, NutritionWsState>(
  NutritionWsNotifier.new,
);
