import 'package:myhealthtrackr/config/app_config.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';

class WeightEntryData {
  const WeightEntryData({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.recordedAt,
    this.createdAt,
  });

  final int id;
  final int userId;
  final double weightKg;
  final DateTime recordedAt;
  final DateTime? createdAt;

  factory WeightEntryData.fromApi(Map<String, dynamic> json) {
    final id = _readNullableInt(json['weight_entry_id']);
    final userId = _readNullableInt(json['user_id']);
    final weightKg = _readNullableDouble(json['weight_kg']);
    final recordedAt = _readNullableDateTime(json['recorded_at']);
    if (id == null ||
        userId == null ||
        weightKg == null ||
        recordedAt == null) {
      throw const ApiFailure('The server returned an invalid weight entry.');
    }

    return WeightEntryData(
      id: id,
      userId: userId,
      weightKg: weightKg,
      recordedAt: recordedAt,
      createdAt: _readNullableDateTime(json['created_at']),
    );
  }
}

class WeightHistoryService {
  const WeightHistoryService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  final ApiClient _apiClient;

  Future<List<WeightEntryData>> fetchWeightEntries({
    required AuthSession session,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    final entriesJson = await _apiClient.getJsonList(
      AppConfig.userWeightEntriesUri(userId),
      session: session,
    );

    final entries =
        entriesJson.map(WeightEntryData.fromApi).toList(growable: false)
          ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));
    return entries;
  }

  Future<WeightEntryData> logCurrentWeight({
    required AuthSession session,
    required double weightKg,
    DateTime? recordedAt,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    final response = await _apiClient.postJson(
      AppConfig.userWeightEntriesUri(userId),
      session: session,
      body: {
        'weight_kg': weightKg,
        if (recordedAt != null)
          'recorded_at': recordedAt.toUtc().toIso8601String(),
      },
    );
    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty weight entry response.',
      );
    }
    return WeightEntryData.fromApi(response);
  }

  Future<WeightEntryData> updateWeightEntry({
    required AuthSession session,
    required int weightEntryId,
    required double weightKg,
    DateTime? recordedAt,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    final response = await _apiClient.putJson(
      AppConfig.userWeightEntryUri(userId, weightEntryId),
      session: session,
      body: {
        'weight_kg': weightKg,
        if (recordedAt != null)
          'recorded_at': recordedAt.toUtc().toIso8601String(),
      },
    );
    if (response == null) {
      throw const ApiFailure(
        'The server returned an empty weight entry response.',
      );
    }
    return WeightEntryData.fromApi(response);
  }

  Future<void> deleteWeightEntry({
    required AuthSession session,
    required int weightEntryId,
  }) async {
    final userId = await _fetchCurrentUserId(session: session);
    await _apiClient.delete(
      AppConfig.userWeightEntryUri(userId, weightEntryId),
      session: session,
    );
  }

  Future<int> _fetchCurrentUserId({required AuthSession session}) async {
    final userJson = await _apiClient.getJson(
      AppConfig.userMeUri(),
      session: session,
    );
    final userId = _readNullableInt(userJson?['id']);
    if (userId == null || userId <= 0) {
      throw const ApiFailure('The server returned an invalid user id.');
    }
    return userId;
  }
}

int? _readNullableInt(Object? value) {
  return switch (value) {
    int number => number,
    String number => int.tryParse(number),
    _ => null,
  };
}

double? _readNullableDouble(Object? value) {
  return switch (value) {
    int number => number.toDouble(),
    double number => number,
    String number => double.tryParse(number),
    _ => null,
  };
}

DateTime? _readNullableDateTime(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}
