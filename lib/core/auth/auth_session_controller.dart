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
    PhoneOtpGateway? phoneOtpGateway,
    AuthSessionStore? sessionStore,
    DateTime Function()? now,
  }) : _authGateway = authGateway ?? AuthService(),
       _sessionStore = sessionStore ?? SecureAuthSessionStore(),
       _now = now ?? DateTime.now {
    _phoneOtpGateway =
        phoneOtpGateway ??
        (_authGateway is PhoneOtpGateway
            ? _authGateway as PhoneOtpGateway
            : null);
  }

  static final AuthSessionController instance = AuthSessionController();

  static const Duration _refreshWindow = Duration(seconds: 30);

  final AuthGateway _authGateway;
  PhoneOtpGateway? _phoneOtpGateway;
  final AuthSessionStore _sessionStore;
  final DateTime Function() _now;

  AuthSession? _session;
  Future<String?>? _refreshRequest;
  bool _isRestoring = false;
  String? _registrationToken;

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

  Future<PhoneOtpChallenge> requestPhoneOtp(String phoneNumber) async {
    final gateway = _phoneOtpGateway;
    if (gateway == null) {
      throw const ApiException('Phone verification is unavailable.');
    }
    _registrationToken = null;
    return gateway.requestPhoneOtp(phoneNumber.trim());
  }

  Future<AuthLoginResult> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final gateway = _phoneOtpGateway;
    if (gateway == null) {
      throw const ApiException('Phone verification is unavailable.');
    }

    final response = await gateway.verifyPhoneOtp(
      phoneNumber: phoneNumber.trim(),
      otp: otp.trim(),
    );
    if (response.isNewUser) {
      final registrationToken = response.registrationToken?.trim();
      if (registrationToken == null || registrationToken.isEmpty) {
        throw const ApiException(
          'The phone verification response is incomplete.',
        );
      }
      _registrationToken = registrationToken;
      return AuthLoginResult.registrationRequired;
    }

    _registrationToken = null;
    await _saveResponse(response);
    return AuthLoginResult.authenticated;
  }

  Future<void> completeRegistration({
    required String phoneNumber,
    required String name,
    required String email,
  }) async {
    final registrationToken = _registrationToken;
    final response =
        registrationToken != null && _authGateway is OtpRegistrationGateway
        ? await (_authGateway as OtpRegistrationGateway)
              .completeVerifiedRegistration(
                phoneNumber: phoneNumber,
                name: name,
                email: email,
                registrationToken: registrationToken,
              )
        : await _authGateway.completeRegistration(
            phoneNumber: phoneNumber,
            name: name,
            email: email,
          );
    _registrationToken = null;
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

  Future<void> updateCachedUser({
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    final current = _session;
    if (current == null) return;
    final user = current.user;
    final updatedName = name ?? user.name;
    final updatedEmail = email ?? user.email;
    final updatedPhoneNumber = phoneNumber ?? user.phoneNumber;
    if (updatedName == user.name &&
        updatedEmail == user.email &&
        updatedPhoneNumber == user.phoneNumber) {
      return;
    }
    final updated = AuthSession(
      user: AuthUser(
        id: user.id,
        name: updatedName,
        email: updatedEmail,
        phoneNumber: updatedPhoneNumber,
        role: user.role,
      ),
      accessToken: current.accessToken,
      refreshToken: current.refreshToken,
      accessTokenExpiresAtUtc: current.accessTokenExpiresAtUtc,
      refreshTokenExpiresAtUtc: current.refreshTokenExpiresAtUtc,
    );
    await _sessionStore.write(updated);
    _session = updated;
    notifyListeners();
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
    _registrationToken = null;
    if (hadSession) {
      notifyListeners();
    }
    await _sessionStore.clear();
  }
}
