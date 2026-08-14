class ApiConstants {
  /// ─────────────────────────────────────────────────────────────────
  /// 🌐 LOCAL DEVELOPMENT IP ADDRESS
  /// ─────────────────────────────────────────────────────────────────
  /// If you are testing on a PHYSICAL device over Wi-Fi, put your computer's 
  /// local IP address here (e.g., 192.168.1.X or 10.X.X.X).
  ///
  /// PERMANENT FIX ADVICE:
  /// To stop this IP from changing every day, log into your Wi-Fi router's 
  /// admin panel and assign a "Static IP" or "DHCP Reservation" to your computer.
  static const String localIp = '10.26.214.49';

  /// The base HTTP URL for the FastAPI backend.
  static const String baseUrl = 'http://$localIp:8000';

  /// The v1 API endpoint prefix.
  static const String apiV1 = '$baseUrl/api/v1';

  /// The WebSocket base URL for the FastAPI backend.
  static const String wsBaseUrl = 'ws://$localIp:8000';
}
