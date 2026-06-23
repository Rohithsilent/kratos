// lib/features/nutrition/data/services/gemini_nutrition_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiNutritionService {
  GenerativeModel? _model;

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );
    return _model!;
  }

  /// Analyze a food image and return nutritional data.
  /// Returns a Map with keys: foodName, calories, protein, carbs, fats, servingSize
  Future<Map<String, dynamic>?> analyzeFoodImage(Uint8List imageBytes) async {
    try {
      final prompt = TextPart('''
Analyze this food image and identify the dish.
Return ONLY a valid JSON object with these exact keys:
{
  "foodName": "name of the dish",
  "calories": estimated calories (number),
  "protein": protein in grams (number),
  "carbs": carbohydrates in grams (number),
  "fats": fats in grams (number),
  "servingSize": estimated serving size in grams (number)
}

Rules:
- Be accurate with Indian, Western, and Asian cuisines.
- Estimate for a standard single serving visible in the image.
- Return ONLY the JSON, no markdown, no explanation.
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) return null;

      // Strip any markdown code fences
      String cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
        cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      }

      return jsonDecode(cleaned.trim()) as Map<String, dynamic>;
    } catch (e, st) {
      print('Gemini API Error: $e');
      print('Stacktrace: $st');
      return null;
    }
  }

  /// Generate AI nutrition coach insights based on today's data.
  Future<String?> generateCoachInsight({
    required double caloriesConsumed,
    required double caloriesTarget,
    required double proteinConsumed,
    required double proteinTarget,
    required double carbsConsumed,
    required double carbsTarget,
    required double fatsConsumed,
    required double fatsTarget,
    required int waterConsumed,
    required int waterTarget,
    String? weight,
    String fitnessGoal = 'maintenance',
  }) async {
    try {
      final prompt = '''
You are a fitness nutrition coach for the KRATOS fitness app.
Analyze today's nutrition data and give 3-4 short, actionable bullet points.

User Profile:
- Weight: ${weight ?? 'Not set'}
- Goal: $fitnessGoal

Today's Intake:
- Calories: ${caloriesConsumed.round()} / ${caloriesTarget.round()} kcal
- Protein: ${proteinConsumed.round()} / ${proteinTarget.round()}g
- Carbs: ${carbsConsumed.round()} / ${carbsTarget.round()}g
- Fats: ${fatsConsumed.round()} / ${fatsTarget.round()}g
- Water: ${waterConsumed}ml / ${waterTarget}ml

Rules:
- Be direct and motivational. No fluff.
- Use bullet points with "•" character.
- Each bullet should be 1-2 sentences max.
- Focus on what to IMPROVE, not what's already good.
- If everything is perfect, say so briefly.
''';

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      return response.text;
    } catch (e) {
      return null;
    }
  }

  /// Suggest meals based on remaining macros.
  Future<List<Map<String, dynamic>>?> suggestMeals({
    required double remainingCalories,
    required double remainingProtein,
    required double remainingCarbs,
    required double remainingFats,
  }) async {
    try {
      final prompt = '''
Suggest 3-4 meals that fit these remaining daily macros:
- Remaining Calories: ${remainingCalories.round()} kcal
- Remaining Protein: ${remainingProtein.round()}g
- Remaining Carbs: ${remainingCarbs.round()}g
- Remaining Fats: ${remainingFats.round()}g

Return ONLY a JSON array with objects containing:
[
  {"name": "meal name", "calories": number, "protein": number, "carbs": number, "fats": number}
]

Rules:
- Include both Indian and international options.
- Keep meals practical and commonly available.
- Return ONLY the JSON array, no markdown, no explanation.
''';

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) return null;

      String cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
        cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      }

      final list = jsonDecode(cleaned.trim()) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }
}

final geminiNutritionServiceProvider = Provider<GeminiNutritionService>((ref) {
  return GeminiNutritionService();
});
