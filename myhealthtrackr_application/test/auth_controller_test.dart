import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myhealthtrackr/services/auth_controller.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/auth_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restoreSession reads tokens from secure storage', () async {
    SharedPreferences.setMockInitialValues({'auth.email': 'test@example.com'});
    final tokenStore = _FakeTokenStore()
      ..values['auth.access_token'] = _fakeJwt(
        subject: '42',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      )
      ..values['auth.refresh_token'] = _fakeJwt(
        subject: '42',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
      )
      ..values['auth.token_type'] = 'bearer';

    final controller = AuthController(
      authService: _FakeAuthService(),
      tokenStore: tokenStore,
    );

    await controller.restoreSession();

    expect(controller.status, AuthStatus.authenticated);
    expect(controller.session?.userId, 42);
    expect(controller.currentEmail, 'test@example.com');
  });

  test('restoreSession migrates legacy SharedPreferences tokens', () async {
    final accessToken = _fakeJwt(
      subject: '7',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    final refreshToken = _fakeJwt(
      subject: '7',
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
    );
    SharedPreferences.setMockInitialValues({
      'auth.access_token': accessToken,
      'auth.refresh_token': refreshToken,
      'auth.token_type': 'bearer',
    });
    final tokenStore = _FakeTokenStore();

    final controller = AuthController(
      authService: _FakeAuthService(),
      tokenStore: tokenStore,
    );

    await controller.restoreSession();
    final preferences = await SharedPreferences.getInstance();

    expect(controller.status, AuthStatus.authenticated);
    expect(tokenStore.values['auth.access_token'], accessToken);
    expect(tokenStore.values['auth.refresh_token'], refreshToken);
    expect(preferences.getString('auth.access_token'), isNull);
    expect(preferences.getString('auth.refresh_token'), isNull);
    expect(preferences.getString('auth.token_type'), isNull);
  });

  test('logout clears secure session tokens', () async {
    SharedPreferences.setMockInitialValues({});
    final tokenStore = _FakeTokenStore()
      ..values['auth.access_token'] = 'access'
      ..values['auth.refresh_token'] = 'refresh'
      ..values['auth.token_type'] = 'bearer';

    final controller = AuthController(
      authService: _FakeAuthService(),
      tokenStore: tokenStore,
    );

    await controller.logout();

    expect(tokenStore.values.containsKey('auth.access_token'), isFalse);
    expect(tokenStore.values.containsKey('auth.refresh_token'), isFalse);
    expect(tokenStore.values.containsKey('auth.token_type'), isFalse);
  });
}

class _FakeTokenStore implements AuthTokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _FakeAuthService extends AuthService {}

String _fakeJwt({required String subject, required DateTime expiresAt}) {
  String encodeJson(Map<String, Object> value) {
    return base64Url
        .encode(utf8.encode(jsonEncode(value)))
        .replaceAll(RegExp(r'=+$'), '');
  }

  final header = encodeJson({'alg': 'HS256', 'typ': 'JWT'});
  final payload = encodeJson({
    'sub': subject,
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    'token_type': 'access',
  });
  return '$header.$payload.signature';
}
