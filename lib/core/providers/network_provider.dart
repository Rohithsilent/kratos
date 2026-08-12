import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  
  // Get initial state
  final initialResult = await connectivity.checkConnectivity();
  yield !initialResult.contains(ConnectivityResult.none);

  // Yield true if any connection type is active, false if only ConnectivityResult.none
  await for (final result in connectivity.onConnectivityChanged) {
    yield !result.contains(ConnectivityResult.none);
  }
});
