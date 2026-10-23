import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/auth_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class NutritionApiService {
  final AuthHttpClient _client;

  NutritionApiService(this._client);

  String get _baseUrl => ApiConstants.apiV1;

  /// Analyze a food image by uploading it to the Python backend.
  Future<Map<String, dynamic>?> analyzeFoodImage(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('$_baseUrl/nutrition/analyze-image');
      final response = await _client.multipartPost(
        uri,
        files: [
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'food.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        ],
      );

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final json = jsonDecode(respStr) as Map<String, dynamic>;
        return {
          'foodName': json['food_name'],
          'calories': json['calories'],
          'protein': json['protein_g'],
          'carbs': json['carbs_g'],
          'fats': json['fats_g'],
        };
      }
      print('analyzeFoodImage error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Nutrition API Error: $e');
      return null;
    }
  }

  /// Calculate daily nutrition score based on macros.
  Future<Map<String, dynamic>?> getNutritionScore({
    required Map<String, dynamic> intake,
    required Map<String, dynamic> targets,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/nutrition/score');
      final response = await _client.post(
        uri,
        body: jsonEncode({'intake': intake, 'targets': targets}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get conversational AI coaching insight.
  Future<String?> generateCoachInsight({
    required Map<String, dynamic> intake,
    required Map<String, dynamic> targets,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/nutrition/coach');
      final response = await _client.post(
        uri,
        body: jsonEncode({'intake': intake, 'targets': targets}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final insight = data['insight'] as String;
        final advice = data['actionable_advice'] as String;
        return '$insight\n\n• $advice';
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final nutritionApiServiceProvider = Provider<NutritionApiService>((ref) {
  return NutritionApiService(ref.watch(authHttpClientProvider));
});
