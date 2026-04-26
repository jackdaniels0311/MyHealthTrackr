import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:myhealthtrackr/services/api_client.dart';
import 'package:myhealthtrackr/services/auth_service.dart';
import 'package:myhealthtrackr/services/auth_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    AuthService? authService,
    AuthTokenStore? tokenStore,
    Future<SharedPreferences>? preferences,
  }) : _authService = authService ?? const AuthService(),
       _tokenStore = tokenStore ?? const SecureAuthTokenStore(),
       _preferences = preferences ?? SharedPreferences.getInstance();

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _tokenTypeKey = 'auth.token_type';
  static const _emailKey = 'auth.email';

  final AuthService _authService;
  final AuthTokenStore _tokenStore;
  final Future<SharedPreferences> _preferences;

  AuthStatus _status = AuthStatus.loading;
  AuthSession? _session;
  String? _currentEmail;
  Future<AuthSession?>? _refreshInFlight;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get currentEmail => _currentEmail;

  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final preferences = await _preferences;
      final storedTokens = await _readStoredSessionTokens(preferences);
      final accessToken = storedTokens.accessToken;
      final refreshToken = storedTokens.refreshToken;
      final tokenType = storedTokens.tokenType;
      _currentEmail = preferences.getString(_emailKey);

      if (accessToken == null || tokenType == null) {
        await _setUnauthenticated(clearStorage: true);
        return;
      }

      final restoredSession = AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
        tokenType: tokenType,
      );

      if (restoredSession.isExpired) {
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedSession = await refreshSession(notify: false);
          if (refreshedSession != null) {
            _session = refreshedSession;
            _status = AuthStatus.authenticated;
            notifyListeners();
            return;
          }
        }

        await _setUnauthenticated(clearStorage: true);
        return;
      }

      _session = restoredSession;
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Failed to restore session: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _setUnauthenticated(clearStorage: true);
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _authService.login(email: email, password: password);
    await _storeSession(session, email: email);
    _session = session;
    _currentEmail = email;
    _status = AuthStatus.authenticated;
    notifyListeners();
    return session;
  }

  Future<AuthSession?> ensureValidSession() async {
    final session = _session;
    if (session == null) return null;
    if (!session.isExpired) return session;
    return refreshSession();
  }

  Future<AuthSession?> refreshSession({bool notify = true}) async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _refreshSessionInternal(notify: notify);
    _refreshInFlight = future;

    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<T> withAuthenticatedSession<T>(
    Future<T> Function(AuthSession session) action,
  ) async {
    final session = await ensureValidSession();
    if (session == null) {
      throw const AuthFailure('Please sign in again to continue.');
    }

    try {
      return await action(session);
    } on ApiFailure catch (error) {
      if (error.statusCode != 401 && error.statusCode != 403) {
        rethrow;
      }

      final refreshedSession = await refreshSession();
      if (refreshedSession == null) {
        throw const AuthFailure(
          'Your session has expired. Please sign in again.',
        );
      }

      return action(refreshedSession);
    }
  }

  Future<void> logout() async {
    await _setUnauthenticated(clearStorage: true);
  }

  Map<String, String> buildAuthHeaders() {
    final session = _session;
    if (session == null) {
      throw StateError('No authenticated session is available.');
    }

    return <String, String>{
      HttpHeaders.authorizationHeader: session.authorizationValue,
    };
  }

  Future<void> _storeSession(AuthSession session, {String? email}) async {
    await _tokenStore.write(_accessTokenKey, session.accessToken);
    await _tokenStore.write(_refreshTokenKey, session.refreshToken);
    await _tokenStore.write(_tokenTypeKey, session.tokenType);
    if (email != null) {
      final preferences = await _preferences;
      await preferences.setString(_emailKey, email);
      _currentEmail = email;
    }
  }

  Future<void> _clearStoredSession() async {
    final preferences = await _preferences;
    await _tokenStore.delete(_accessTokenKey);
    await _tokenStore.delete(_refreshTokenKey);
    await _tokenStore.delete(_tokenTypeKey);
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_tokenTypeKey);
    await preferences.remove(_emailKey);
  }

  Future<AuthSession?> _refreshSessionInternal({required bool notify}) async {
    final refreshToken =
        _session?.refreshToken ?? await _readStoredValue(_refreshTokenKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      await _setUnauthenticated(clearStorage: true, notify: notify);
      return null;
    }

    try {
      final refreshedSession = await _authService.refresh(
        refreshToken: refreshToken,
      );
      await _storeSession(refreshedSession, email: _currentEmail);
      _session = refreshedSession;
      _status = AuthStatus.authenticated;
      if (notify) {
        notifyListeners();
      }
      return refreshedSession;
    } on AuthFailure {
      await _setUnauthenticated(clearStorage: true, notify: notify);
      return null;
    }
  }

  Future<String?> _readStoredValue(String key) async {
    return _tokenStore.read(key);
  }

  Future<_StoredSessionTokens> _readStoredSessionTokens(
    SharedPreferences preferences,
  ) async {
    var accessToken = await _tokenStore.read(_accessTokenKey);
    var refreshToken = await _tokenStore.read(_refreshTokenKey);
    var tokenType = await _tokenStore.read(_tokenTypeKey);

    final legacyAccessToken = preferences.getString(_accessTokenKey);
    final legacyRefreshToken = preferences.getString(_refreshTokenKey);
    final legacyTokenType = preferences.getString(_tokenTypeKey);
    final hasLegacyTokens =
        legacyAccessToken != null ||
        legacyRefreshToken != null ||
        legacyTokenType != null;

    if (accessToken == null && legacyAccessToken != null) {
      accessToken = legacyAccessToken;
      await _tokenStore.write(_accessTokenKey, legacyAccessToken);
    }
    if (refreshToken == null && legacyRefreshToken != null) {
      refreshToken = legacyRefreshToken;
      await _tokenStore.write(_refreshTokenKey, legacyRefreshToken);
    }
    if (tokenType == null && legacyTokenType != null) {
      tokenType = legacyTokenType;
      await _tokenStore.write(_tokenTypeKey, legacyTokenType);
    }

    if (hasLegacyTokens) {
      await preferences.remove(_accessTokenKey);
      await preferences.remove(_refreshTokenKey);
      await preferences.remove(_tokenTypeKey);
    }

    return _StoredSessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
    );
  }

  Future<void> _setUnauthenticated({
    required bool clearStorage,
    bool notify = true,
  }) async {
    if (clearStorage) {
      await _clearStoredSession();
    }

    _session = null;
    _currentEmail = null;
    _status = AuthStatus.unauthenticated;

    if (notify) {
      notifyListeners();
    }
  }
}

class _StoredSessionTokens {
  const _StoredSessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
}
