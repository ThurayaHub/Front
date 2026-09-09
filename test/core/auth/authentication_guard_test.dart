import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/auth_service.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/auth/auth_session_store.dart';
import 'package:thuraya/core/auth/authentication_guard.dart';
import 'package:thuraya/core/auth/models/auth_models.dart';
import 'package:thuraya/core/routing/app_route_names.dart';

void main() {
  testWidgets('logs in, returns, and executes a protected action once', (
    tester,
  ) async {
    final controller = _controller();
    var actionCount = 0;
    await tester.pumpWidget(
      _GuardTestApp(
        controller: controller,
        onAction: () async => actionCount++,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('protected-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('test-login-page')), findsOneWidget);
    expect(actionCount, 0);

    await tester.tap(find.byKey(const ValueKey('test-login-success')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('test-login-page')), findsNothing);
    expect(controller.isAuthenticated, isTrue);
    expect(actionCount, 1);
  });

  testWidgets('does not execute a protected action when login is cancelled', (
    tester,
  ) async {
    final controller = _controller();
    var actionCount = 0;
    await tester.pumpWidget(
      _GuardTestApp(
        controller: controller,
        onAction: () async => actionCount++,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('protected-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('test-login-cancel')));
    await tester.pumpAndSettle();

    expect(controller.isAuthenticated, isFalse);
    expect(actionCount, 0);
  });

  testWidgets('executes immediately when already authenticated', (
    tester,
  ) async {
    final controller = _controller();
    await controller.loginWithPhone('+966500000000');
    var actionCount = 0;
    await tester.pumpWidget(
      _GuardTestApp(
        controller: controller,
        onAction: () async => actionCount++,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('protected-action')));
    await tester.pump();

    expect(find.byKey(const ValueKey('test-login-page')), findsNothing);
    expect(actionCount, 1);
  });
}

AuthSessionController _controller() {
  return AuthSessionController(
    authGateway: _GuardAuthGateway(),
    sessionStore: _GuardSessionStore(),
    now: () => DateTime.utc(2026, 9, 8, 12),
  );
}

class _GuardTestApp extends StatelessWidget {
  const _GuardTestApp({required this.controller, required this.onAction});

  final AuthSessionController controller;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: controller,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const ValueKey('protected-action'),
              onPressed: () =>
                  AuthenticationGuard.requireAuthentication(context, onAction),
              child: const Text('Protected'),
            ),
          ),
        ),
        routes: {
          AppRouteNames.login: (context) => Scaffold(
            key: const ValueKey('test-login-page'),
            body: Column(
              children: [
                TextButton(
                  key: const ValueKey('test-login-success'),
                  onPressed: () async {
                    await controller.loginWithPhone('+966500000000');
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('Login'),
                ),
                TextButton(
                  key: const ValueKey('test-login-cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

class _GuardAuthGateway implements AuthGateway {
  AuthResponse get _response => AuthResponse(
    isNewUser: false,
    user: const AuthUser(
      id: 1,
      name: 'User',
      email: 'user@example.com',
      phoneNumber: '+966500000000',
      role: 'User',
    ),
    accessToken: 'access',
    refreshToken: 'refresh',
    accessTokenExpiresAtUtc: DateTime.utc(2026, 9, 8, 12, 15),
    refreshTokenExpiresAtUtc: DateTime.utc(2026, 10, 8, 12),
  );

  @override
  Future<AuthResponse> loginWithPhone(String phoneNumber) async => _response;

  @override
  Future<AuthResponse> completeRegistration({
    required String phoneNumber,
    required String name,
    required String email,
  }) async => _response;

  @override
  Future<AuthResponse> refresh(String refreshToken) async => _response;

  @override
  Future<void> logout(String refreshToken) async {}
}

class _GuardSessionStore implements AuthSessionStore {
  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}
