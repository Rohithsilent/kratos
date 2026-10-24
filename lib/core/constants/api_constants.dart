class ApiConstants {
  /// Override this at build time for each environment:
  /// --dart-define=API_BASE_URL=https://your-api.example.com
  ///
  /// The default keeps local physical-device development working.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.41.204.177:8000',
  );

  /// The v1 API endpoint prefix.
  static const String apiV1 = '$baseUrl/api/v1';

  /// Uses ws for local HTTP and wss for a deployed HTTPS API.
  static String get wsBaseUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: scheme).toString();
  }
}
