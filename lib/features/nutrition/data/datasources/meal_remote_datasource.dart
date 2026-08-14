// lib/features/nutrition/data/datasources/meal_remote_datasource.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/meal_entry_model.dart';

abstract class MealRemoteDataSource {
  Future<List<MealEntry>> getMeals(String uid, {String? date});
  Future<void> saveMeal(String uid, MealEntry meal);
  Future<void> deleteMeal(String uid, String mealId);
  Future<List<MealEntry>> getMealsForDateRange(
      String uid, String startDate, String endDate);
}

class MealRemoteDataSourceImpl implements MealRemoteDataSource {
  final String _baseUrl = ApiConstants.apiV1;

  @override
  Future<List<MealEntry>> getMeals(String uid, {String? date}) async {
    try {
      var uri = Uri.parse('$_baseUrl/meals/$uid');
      if (date != null) {
        uri = uri.replace(queryParameters: {'date': date});
      }
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('[MealDataSource] getMeals uid=$uid date=$date → ${data.length} docs');
        return data.map((json) => MealEntry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load meals: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('[MealDataSource] ERROR getMeals: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> saveMeal(String uid, MealEntry meal) async {
    try {
      final uri = Uri.parse('$_baseUrl/meals/$uid');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(meal.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('[MealDataSource] saveMeal OK: ${meal.foodName} → ${meal.id}');
      } else {
        throw Exception('Failed to save meal: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('[MealDataSource] ERROR saveMeal: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> deleteMeal(String uid, String mealId) async {
    try {
      final uri = Uri.parse('$_baseUrl/meals/$uid/$mealId');
      final response = await http.delete(uri);

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('[MealDataSource] deleteMeal OK: $mealId');
      } else {
        throw Exception('Failed to delete meal: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('[MealDataSource] ERROR deleteMeal: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<List<MealEntry>> getMealsForDateRange(
      String uid, String startDate, String endDate) async {
    try {
      final uri = Uri.parse('$_baseUrl/meals/$uid').replace(
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
        },
      );
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('[MealDataSource] getMealsForDateRange $startDate→$endDate: ${data.length} docs');
        return data.map((json) => MealEntry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load meals: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('[MealDataSource] ERROR getMealsForDateRange: $e\n$st');
      rethrow;
    }
  }
}

final mealRemoteDataSourceProvider = Provider<MealRemoteDataSource>((ref) {
  return MealRemoteDataSourceImpl();
});
