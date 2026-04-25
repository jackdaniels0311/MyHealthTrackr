import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:myhealthtrackr/services/auth_service.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  const ApiClient({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory;

  final HttpClient Function()? _clientFactory;

  Future<Map<String, dynamic>?> getJson(Uri uri, {AuthSession? session}) async {
    return _sendJsonRequest(uri, method: 'GET', session: session);
  }

  Future<List<Map<String, dynamic>>> getJsonList(
    Uri uri, {
    AuthSession? session,
  }) async {
    return _sendJsonListRequest(uri, session: session);
  }

  Future<Map<String, dynamic>?> postJson(
    Uri uri, {
    AuthSession? session,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _sendJsonRequest(
      uri,
      method: 'POST',
      session: session,
      body: body,
      timeout: timeout,
    );
  }

  Future<Map<String, dynamic>?> putJson(
    Uri uri, {
    AuthSession? session,
    Map<String, dynamic>? body,
  }) async {
    return _sendJsonRequest(uri, method: 'PUT', session: session, body: body);
  }

  Future<void> delete(Uri uri, {AuthSession? session}) async {
    await _sendJsonRequest(uri, method: 'DELETE', session: session);
  }

  Future<Map<String, dynamic>?> _sendJsonRequest(
    Uri uri, {
    required String method,
    AuthSession? session,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final httpClient = (_clientFactory ?? HttpClient.new).call();

    try {
      final request = switch (method) {
        'GET' => await httpClient.getUrl(uri),
        'POST' => await httpClient.postUrl(uri),
        'PUT' => await httpClient.putUrl(uri),
        'DELETE' => await httpClient.deleteUrl(uri),
        _ => throw UnsupportedError('Unsupported HTTP method: $method'),
      };

      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      if (session != null) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          session.authorizationValue,
        );
      }

      if (body != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      final responseJson = _decodeObject(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseJson;
      }

      throw ApiFailure(
        responseJson?['detail']?.toString() ??
            responseJson?['message']?.toString() ??
            'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const ApiFailure('Unable to reach the API server.');
    } on TimeoutException {
      throw const ApiFailure('The API request timed out.');
    } on FormatException {
      throw const ApiFailure('The API response was not valid JSON.');
    } finally {
      httpClient.close(force: true);
    }
  }

  Future<List<Map<String, dynamic>>> _sendJsonListRequest(
    Uri uri, {
    AuthSession? session,
  }) async {
    final httpClient = (_clientFactory ?? HttpClient.new).call();

    try {
      final request = await httpClient.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      if (session != null) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          session.authorizationValue,
        );
      }

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decodeList(responseBody);
      }

      final responseJson = _decodeObject(responseBody);
      throw ApiFailure(
        responseJson?['detail']?.toString() ??
            responseJson?['message']?.toString() ??
            'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const ApiFailure('Unable to reach the API server.');
    } on TimeoutException {
      throw const ApiFailure('The API request timed out.');
    } on FormatException {
      throw const ApiFailure('The API response was not valid JSON.');
    } finally {
      httpClient.close(force: true);
    }
  }

  Map<String, dynamic>? _decodeObject(String responseBody) {
    if (responseBody.trim().isEmpty) return null;

    final decoded = jsonDecode(responseBody);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  List<Map<String, dynamic>> _decodeList(String responseBody) {
    if (responseBody.trim().isEmpty) return const <Map<String, dynamic>>[];

    final decoded = jsonDecode(responseBody);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array.');
    }

    return decoded.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }

      throw const FormatException(
        'Expected each array item to be a JSON object.',
      );
    }).toList();
  }
}
