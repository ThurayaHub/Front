import 'package:flutter/foundation.dart';
import 'package:thuraya/core/auth/auth_service.dart';
import 'package:thuraya/core/auth/auth_session_store.dart';
import 'package:thuraya/core/auth/models/auth_models.dart';
import 'package:thuraya/core/network/api_client.dart';

enum AuthLoginResult { authenticated, registrationRequired }

class AuthSessionController extends ChangeNotifier
    implements ApiAuthorizationDelegate {
  AuthSessionController({
    AuthGateway? authGateway,
    AuthSessionStore? sessionStore,
    DateTime Function()? now,
  }) : _authGateway = authGateway ?? AuthService(),
       _sessionStore = sessionStore ?? SecureAuthSessionStore(),
       _now = now ?? DateTime.now;

  static final AuthSessionController instance = AuthSessionController();

  static const Duration _refreshWindow = Duration(seconds: 30);

  final AuthGateway _authGateway;
  final AuthSessionStore _sessionStore;
  final DateTime Function() _now;

  AuthSession? _session;
  Future<String?>? _refreshRequest;
  bool _isRestoring = false;

  AuthSession? get session => _session;
  AuthUser? get user => _session?.user;
  bool get isAuthenticated => _session != null;
  bool get isRestoring => _isRestoring;

  Future<void> restoreSession() async {
    if (_isRestoring) {
      return;
    }

    _isRestoring = true;
    notifyListeners();
    try {
      final storedSession = await _sessionStore.read();
      if (storedSession == null) {
        _session = null;
        return;
      }

      if (!_isRefreshTokenUsable(storedSession)) {
        await clearSession();
        return;
      }

      _session = storedSession;
      if (!_isAccessTokenUsable(storedSession)) {
        await refreshAccessToken();
      }
    } catch (_) {
      _session = null;
      try {
        await _sessionStore.clear();
      } catch (_) {
        // The in-memory state must still be anonymous if secure storage fails.
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<AuthLoginResult> loginWithPhone(String phoneNumber) async {
    final response = await _authGateway.loginWithPhone(phoneNumber.trim());
    if (response.isNewUser) {
      return AuthLoginResult.registrationRequired;
    }

    await _saveResponse(response);
    return AuthLoginResult.authenticated;
  }

  Future<void> completeRegistration({
    required String phoneNumber,
    required String name,
    required String email,
  }) async {
    final response = await _authGateway.completeRegistration(
      phoneNumber: phoneNumber,
      name: name,
      email: email,
    );
    await _saveResponse(response);
  }

  Future<void> logout() async {
    final refreshToken = _session?.refreshToken;
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _authGateway.logout(refreshToken);
      }
    } finally {
      await clearSession();
    }
  }

  @override
  Future<String?> getAccessToken() async {
    final currentSession = _session;
    if (currentSession == null) {
      return null;
    }
    if (!_isRefreshTokenUsable(currentSession)) {
      await clearSession();
      return null;
    }
    if (_isAccessTokenUsable(currentSession)) {
      return currentSession.accessToken;
    }
    return refreshAccessToken();
  }

  @override
  Future<String?> refreshAccessToken() async {
    final existingRequest = _refreshRequest;
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _performRefresh();
    _refreshRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_refreshRequest, request)) {
        _refreshRequest = null;
      }
    }
  }

  Future<String?> _performRefresh() async {
    final currentSession = _session;
    if (currentSession == null) {
      return null;
    }
    if (!_isRefreshTokenUsable(currentSession)) {
      await clearSession();
      return null;
    }

    try {
      final response = await _authGateway.refresh(currentSession.refreshToken);
      final refreshedSession = await _saveResponse(response);
      return refreshedSession.accessToken;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await clearSession();
        return null;
      }
      rethrow;
    }
  }

  Future<AuthSession> _saveResponse(AuthResponse response) async {
    final newSession = response.toSession();
    if (newSession == null) {
      throw const ApiException('The authentication response is incomplete.');
    }
    await _sessionStore.write(newSession);
    _session = newSession;
    notifyListeners();
    return newSession;
  }

  bool _isAccessTokenUsable(AuthSession candidate) {
    return candidate.accessTokenExpiresAtUtc.isAfter(
      _now().toUtc().add(_refreshWindow),
    );
  }

  bool _isRefreshTokenUsable(AuthSession candidate) {
    return candidate.refreshTokenExpiresAtUtc.isAfter(_now().toUtc());
  }

  @override
  Future<void> clearSession() async {
    final hadSession = _session != null;
    _session = null;
    if (hadSession) {
      notifyListeners();
    }
    await _sessionStore.clear();
  }
}
