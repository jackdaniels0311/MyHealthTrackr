import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String _productionApiBaseUrl =
      'https://api-myhealthtrackr.duckdns.org';
  static const String _localDevelopmentApiBaseUrl = 'http://127.0.0.1:8000';

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    final baseUrl = override.isNotEmpty
        ? override
        : Platform.isAndroid || Platform.isIOS
        ? _productionApiBaseUrl
        : _localDevelopmentApiBaseUrl;

    return _requireSecureReleaseUrl(_normalizeBaseUrl(baseUrl));
  }

  static Uri authLoginUri() =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/auth/login');
  static Uri authRefreshUri() =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/auth/refresh');
  static Uri userCreateUri() =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/users');
  static Uri userMeUri() =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/users/me');
  static Uri userProfileUri() =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/users/profile');
  static Uri userNutritionTargetsUri(int userId) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/nutrition-targets',
  );
  static Uri foodBarcodeUri(String barcode) =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/foods/barcode/$barcode');
  static Uri foodSearchUri(String query, {int pageSize = 10}) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/foods/search',
  ).replace(queryParameters: {'q': query, 'page_size': '$pageSize'});
  static Uri userFoodSearchUri(
    String query, {
    int pageSize = 10,
    String? mealType,
  }) => Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/users/me/foods/search')
      .replace(
        queryParameters: {
          'q': query,
          'page_size': '$pageSize',
          if (mealType != null && mealType.trim().isNotEmpty)
            'meal_type': mealType,
        },
      );
  static Uri userGoalsUri(int userId) =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/goals');
  static Uri userGoalUri(int userId, int goalId) =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/goals/$goalId');
  static Uri userFoodLogsUri(int userId) =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/food-logs');
  static Uri userMealLogsUri(int userId, {int? foodLogId}) =>
      Uri.parse(
        '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/meal-logs',
      ).replace(
        queryParameters: foodLogId == null
            ? null
            : {'food_log_id': '$foodLogId'},
      );
  static Uri userMealItemsUri(int userId, {int? mealLogId}) =>
      Uri.parse(
        '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/meal-items',
      ).replace(
        queryParameters: mealLogId == null
            ? null
            : {'meal_log_id': '$mealLogId'},
      );
  static Uri userMealItemUri(int userId, int mealItemId) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/meal-items/$mealItemId',
  );
  static Uri userSavedMealsUri(int userId) =>
      Uri.parse('${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/saved-meals');
  static Uri userSavedMealUri(int userId, int savedMealId) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/saved-meals/$savedMealId',
  );
  static Uri userSavedMealLogUri(int userId, int savedMealId) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/saved-meals/$savedMealId/log',
  );
  static Uri userMealPlanGenerateUri(int userId) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/meal-plans/generate',
  );
  static Uri userMealPlanPreferencesUri(int userId) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/meal-plans/preferences',
  );
  static Uri userWeightEntriesUri(int userId) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/weight-entries',
  );
  static Uri userWeightEntryUri(int userId, int weightEntryId) => Uri.parse(
    '${_normalizeBaseUrl(apiBaseUrl)}/users/$userId/weight-entries/$weightEntryId',
  );

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String _requireSecureReleaseUrl(String value) {
    if (kReleaseMode && Uri.parse(value).scheme != 'https') {
      throw StateError(
        'API_BASE_URL must use HTTPS in release builds to protect auth traffic.',
      );
    }
    return value;
  }
}
