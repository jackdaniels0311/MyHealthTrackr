import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:myhealthtrackr/config/app_config.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;

  String get authorizationValue => '$tokenType $accessToken';

  int? get userId {
    final payload = _decodeJwtPayload(accessToken);
    final subject = payload?['sub'];
    return switch (subject) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };
  }

  bool get isExpired {
    return _isTokenExpired(accessToken);
  }

  bool get isRefreshTokenExpired {
    return _isTokenExpired(refreshToken);
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : null;
    } on FormatException {
      return null;
    }
  }

  static bool _isTokenExpired(String token) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    final expirySeconds = switch (exp) {
      int value => value,
      String value => int.tryParse(value) ?? -1,
      _ => -1,
    };

    if (expirySeconds <= 0) return true;

    final expiry = DateTime.fromMillisecondsSinceEpoch(
      expirySeconds * 1000,
      isUtc: true,
    );

    return !expiry.isAfter(DateTime.now().toUtc());
  }
}

class AuthService {
  const AuthService({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory;

  final HttpClient Function()? _clientFactory;

  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final httpClient = (_clientFactory ?? HttpClient.new).call();

    try {
      final request = await httpClient.postUrl(AppConfig.userCreateUri());
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(
        jsonEncode({
          'name': name.trim().isEmpty ? null : name.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));

      final responseJson = _decodeObject(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      throw AuthFailure(
        responseJson?['detail']?.toString() ??
            'Unable to create account. Please try again.',
      );
    } on TimeoutException {
      throw const AuthFailure(
        'Create account request timed out. Check API_BASE_URL and that the backend is reachable.',
      );
    } on SocketException {
      throw const AuthFailure(
        'Unable to reach the server. Check API_BASE_URL and that your backend is running.',
      );
    } on FormatException {
      throw const AuthFailure('The server response was not valid JSON.');
    } finally {
      httpClient.close(force: true);
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final httpClient = (_clientFactory ?? HttpClient.new).call();

    try {
      final request = await httpClient.postUrl(AppConfig.authLoginUri());
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/x-www-form-urlencoded',
      );
      request.write(
        'username=${Uri.encodeQueryComponent(email)}'
        '&password=${Uri.encodeQueryComponent(password)}',
      );

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));

      final responseJson = _decodeObject(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _sessionFromResponse(responseJson);
      }

      throw AuthFailure(
        responseJson?['detail']?.toString() ??
            'Login failed. Please check your email and password.',
      );
    } on TimeoutException {
      throw const AuthFailure(
        'Login request timed out. Check API_BASE_URL and that the backend is reachable.',
      );
    } on SocketException {
      throw const AuthFailure(
        'Unable to reach the server. Check API_BASE_URL and that your backend is running.',
      );
    } on FormatException {
      throw const AuthFailure('The server response was not valid JSON.');
    } finally {
      httpClient.close(force: true);
    }
  }

  Future<AuthSession> refresh({required String refreshToken}) async {
    final httpClient = (_clientFactory ?? HttpClient.new).call();

    try {
      final request = await httpClient.postUrl(AppConfig.authRefreshUri());
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode({'refresh_token': refreshToken}));

      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      final responseBody = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));

      final responseJson = _decodeObject(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _sessionFromResponse(responseJson);
      }

      throw AuthFailure(
        responseJson?['detail']?.toString() ??
            'Your session has expired. Please sign in again.',
      );
    } on TimeoutException {
      throw const AuthFailure(
        'Session refresh timed out. Please check your connection and try again.',
      );
    } on SocketException {
      throw const AuthFailure(
        'Unable to reach the server to refresh your session.',
      );
    } on FormatException {
      throw const AuthFailure('The server response was not valid JSON.');
    } finally {
      httpClient.close(force: true);
    }
  }

  Map<String, dynamic>? _decodeObject(String responseBody) {
    if (responseBody.trim().isEmpty) return null;

    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const FormatException('Expected a JSON object.');
  }

  AuthSession _sessionFromResponse(Map<String, dynamic>? responseJson) {
    final accessToken = responseJson?['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthFailure('The server did not return an access token.');
    }

    final refreshToken = responseJson?['refresh_token']?.toString();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthFailure('The server did not return a refresh token.');
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: responseJson?['token_type']?.toString() ?? 'bearer',
    );
  }
}
