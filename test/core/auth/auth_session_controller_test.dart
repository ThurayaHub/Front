import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/auth/auth_service.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/auth/auth_session_store.dart';
import 'package:thuraya/core/auth/models/auth_models.dart';
import 'package:thuraya/core/network/api_client.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8, 12);

  test('logs in an existing user and persists the session', () async {
    final store = _MemorySessionStore();
    final gateway = _FakeAuthGateway(existingUserResponse: _response(now));
    final controller = AuthSessionController(
      authGateway: gateway,
      sessionStore: store,
      now: () => now,
    );

    final result = await controller.loginWithPhone('+966500000000');

    expect(result, AuthLoginResult.authenticated);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.user?.name, 'Thuraya User');
    expect(store.session?.accessToken, 'access-1');
  });

  test('keeps the session anonymous when registration is required', () async {
    final store = _MemorySessionStore();
    final gateway = _FakeAuthGateway(
      existingUserResponse: const AuthResponse(
        isNewUser: true,
        user: null,
        accessToken: null,
        refreshToken: null,
        accessTokenExpiresAtUtc: null,
        refreshTokenExpiresAtUtc: null,
      ),
    );
    final controller = AuthSessionController(
      authGateway: gateway,
      sessionStore: store,
      now: () => now,
    );

    final result = await controller.loginWithPhone('+966511111111');

    expect(result, AuthLoginResult.registrationRequired);
    expect(controller.isAuthenticated, isFalse);
    expect(store.session, isNull);
  });

  test('restores a valid session after restart', () async {
    final session = _response(now).toSession()!;
    final store = _MemorySessionStore()..session = session;
    final controller = AuthSessionController(
      authGateway: _FakeAuthGateway(existingUserResponse: _response(now)),
      sessionStore: store,
      now: () => now,
    );

    await controller.restoreSession();

    expect(controller.isAuthenticated, isTrue);
    expect(controller.session?.refreshToken, 'refresh-1');
  });

  test('refreshes an expired access token during restoration', () async {
    final expiredAccess = _response(
      now,
      accessToken: 'expired-access',
      accessExpiry: now.subtract(const Duration(minutes: 1)),
    ).toSession()!;
    final refreshed = _response(
      now,
      accessToken: 'access-2',
      refreshToken: 'refresh-2',
    );
    final store = _MemorySessionStore()..session = expiredAccess;
    final gateway = _FakeAuthGateway(
      existingUserResponse: _response(now),
      refreshResponse: refreshed,
    );
    final controller = AuthSessionController(
      authGateway: gateway,
      sessionStore: store,
      now: () => now,
    );

    await controller.restoreSession();

    expect(gateway.refreshedWith, ['refresh-1']);
    expect(controller.session?.accessToken, 'access-2');
    expect(store.session?.refreshToken, 'refresh-2');
  });

  test('clears an invalid session when refresh is unauthorized', () async {
    final expiredAccess = _response(
      now,
      accessExpiry: now.subtract(const Duration(minutes: 1)),
    ).toSession()!;
    final store = _MemorySessionStore()..session = expiredAccess;
    final gateway = _FakeAuthGateway(
      existingUserResponse: _response(now),
      refreshError: const ApiException('Invalid token', statusCode: 401),
    );
    final controller = AuthSessionController(
      authGateway: gateway,
      sessionStore: store,
      now: () => now,
    );

    await controller.restoreSession();

    expect(controller.isAuthenticated, isFalse);
    expect(store.session, isNull);
  });

  test('logout revokes the refresh token and clears storage', () async {
    final store = _MemorySessionStore();
    final gateway = _FakeAuthGateway(existingUserResponse: _response(now));
    final controller = AuthSessionController(
      authGateway: gateway,
      sessionStore: store,
      now: () => now,
    );
    await controller.loginWithPhone('+966500000000');

    await controller.logout();

    expect(gateway.loggedOutWith, ['refresh-1']);
    expect(controller.isAuthenticated, isFalse);
    expect(store.session, isNull);
  });
}

AuthResponse _response(
  DateTime now, {
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
  DateTime? accessExpiry,
}) {
  return AuthResponse(
    isNewUser: false,
    user: const AuthUser(
      id: 7,
      name: 'Thuraya User',
      email: 'user@example.com',
      phoneNumber: '+966500000000',
      role: 'User',
    ),
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessTokenExpiresAtUtc:
        accessExpiry ?? now.add(const Duration(minutes: 15)),
    refreshTokenExpiresAtUtc: now.add(const Duration(days: 30)),
  );
}

class _MemorySessionStore implements AuthSessionStore {
  AuthSession? session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async {
    this.session = session;
  }

  @override
  Future<void> clear() async {
    session = null;
  }
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({
    required this.existingUserResponse,
    this.refreshResponse,
    this.refreshError,
  });

  final AuthResponse existingUserResponse;
  final AuthResponse? refreshResponse;
  final ApiException? refreshError;
  final List<String> refreshedWith = [];
  final List<String> loggedOutWith = [];

  @override
  Future<AuthResponse> loginWithPhone(String phoneNumber) async {
    return existingUserResponse;
  }

  @override
  Future<AuthResponse> completeRegistration({
    required String phoneNumber,
    required String name,
    required String email,
  }) async {
    return existingUserResponse;
  }

  @override
  Future<AuthResponse> refresh(String refreshToken) async {
    refreshedWith.add(refreshToken);
    final error = refreshError;
    if (error != null) {
      throw error;
    }
    return refreshResponse ?? existingUserResponse;
  }

  @override
  Future<void> logout(String refreshToken) async {
    loggedOutWith.add(refreshToken);
  }
}
