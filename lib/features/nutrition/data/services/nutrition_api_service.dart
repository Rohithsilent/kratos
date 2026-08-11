import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class NutritionApiService {
  // Use local network IP for physical device testing
  String get _baseUrl {
    return 'http://172.31.0.176:8000/api/v1';
  }

  /// Analyze a food image by uploading it to the Python backend.
  Future<Map<String, dynamic>?> analyzeFoodImage(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('$_baseUrl/nutrition/analyze-image');
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'food.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        // The backend returns: food_name, calories, protein_g, carbs_g, fats_g, confidence
        // We will map it to the structure the frontend expects.
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
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'intake': intake,
          'targets': targets,
        }),
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
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'intake': intake,
          'targets': targets,
        }),
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
  return NutritionApiService();
});
