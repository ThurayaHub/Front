import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/auth_service.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/auth/auth_session_store.dart';
import 'package:thuraya/core/auth/models/auth_models.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/widgets/thuraya_logo.dart';
import 'package:thuraya/features/authentication/presentation/login_page.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('logs in an existing phone user and returns to the caller', (
    tester,
  ) async {
    final gateway = _LoginGateway(isNewUser: false);
    final controller = _controller(gateway);
    await tester.pumpWidget(_LoginTestApp(controller: controller));

    await tester.tap(find.byKey(const ValueKey('open-login')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login-page')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('authentication-thuraya-logo')),
      findsOneWidget,
    );
    expect(find.byType(ThurayaLogo), findsOneWidget);
    expect(find.text('مرحباً بك في ثريا'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('تسجيل الدخول'))),
      TextDirection.rtl,
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-phone')),
      '0500000000',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(gateway.loggedInPhones, ['0500000000']);
    expect(controller.isAuthenticated, isTrue);
    expect(find.byKey(const ValueKey('login-page')), findsNothing);
  });

  testWidgets('completes the backend registration flow for a new phone', (
    tester,
  ) async {
    final gateway = _LoginGateway(isNewUser: true);
    final controller = _controller(gateway);
    await tester.pumpWidget(_LoginTestApp(controller: controller));
    await tester.tap(find.byKey(const ValueKey('open-login')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('login-phone')),
      '0511111111',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('login-registration-step')),
      findsOneWidget,
    );
    expect(find.byType(ThurayaLogo), findsOneWidget);
    expect(find.text('مرحباً بك في ثريا'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('registration-name')),
      'مستخدم ثريا',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-email')),
      'new@example.com',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('registration-submit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('registration-submit')));
    await tester.pumpAndSettle();

    expect(gateway.registration, (
      '0511111111',
      'مستخدم ثريا',
      'new@example.com',
    ));
    expect(controller.isAuthenticated, isTrue);
    expect(find.byKey(const ValueKey('login-page')), findsNothing);
  });

  testWidgets('branded authentication header fits a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = _controller(_LoginGateway(isNewUser: false));
    await tester.pumpWidget(_LoginTestApp(controller: controller));
    await tester.tap(find.byKey(const ValueKey('open-login')));
    await tester.pumpAndSettle();

    final logo = tester.widget<ThurayaLogo>(find.byType(ThurayaLogo));
    expect(logo.height, 88);
    expect(find.text('مرحباً بك في ثريا'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('limits registration fields and validates Saudi phone format', (
    tester,
  ) async {
    final gateway = _LoginGateway(isNewUser: true);
    final controller = _controller(gateway);
    await tester.pumpWidget(_LoginTestApp(controller: controller));
    await tester.tap(find.byKey(const ValueKey('open-login')));
    await tester.pumpAndSettle();

    final phoneField = find.byKey(const ValueKey('login-phone'));
    final phoneWidget = tester.widget<TextField>(
      find.descendant(of: phoneField, matching: find.byType(TextField)),
    );
    expect(phoneWidget.decoration?.hintText, '05XXXXXXXX');

    await tester.enterText(phoneField, '061234567890');
    expect(phoneWidget.controller?.text, '0612345678');
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    expect(
      find.text('أدخل رقم جوال سعودي صحيحاً من 10 أرقام يبدأ بـ 05'),
      findsOneWidget,
    );
    expect(gateway.loggedInPhones, isEmpty);

    await tester.enterText(phoneField, '0512345678');
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    final longName = List.filled(50, 'ن').join();
    final longEmail = '${List.filled(60, 'a').join()}@example.com';
    final nameField = find.byKey(const ValueKey('registration-name'));
    final emailField = find.byKey(const ValueKey('registration-email'));
    await tester.enterText(nameField, longName);
    await tester.enterText(emailField, longEmail);

    final nameWidget = tester.widget<TextField>(
      find.descendant(of: nameField, matching: find.byType(TextField)),
    );
    final emailWidget = tester.widget<TextField>(
      find.descendant(of: emailField, matching: find.byType(TextField)),
    );
    expect(nameWidget.controller?.text.length, 40);
    expect(emailWidget.controller?.text.length, 60);
  });

  testWidgets('rejects invalid registration name and email characters', (
    tester,
  ) async {
    final gateway = _LoginGateway(isNewUser: true);
    final controller = _controller(gateway);
    await tester.pumpWidget(_LoginTestApp(controller: controller));
    await tester.tap(find.byKey(const ValueKey('open-login')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('login-phone')),
      '0512345678',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const ValueKey('registration-name'));
    final emailField = find.byKey(const ValueKey('registration-email'));
    await tester.enterText(nameField, 'يتيريريروينين 👍👍');
    await tester.enterText(emailField, '👍👍👍👍');

    final nameWidget = tester.widget<TextField>(
      find.descendant(of: nameField, matching: find.byType(TextField)),
    );
    final emailWidget = tester.widget<TextField>(
      find.descendant(of: emailField, matching: find.byType(TextField)),
    );
    expect(nameWidget.controller?.text, 'يتيريريروينين ');
    expect(emailWidget.controller?.text, isEmpty);

    await tester.ensureVisible(
      find.byKey(const ValueKey('registration-submit')),
    );
    await tester.tap(find.byKey(const ValueKey('registration-submit')));
    await tester.pump();

    expect(
      find.text('يقبل الاسم الحروف العربية أو الإنجليزية والمسافات فقط'),
      findsOneWidget,
    );
    expect(
      find.text('البريد الإلكتروني يحتوي على أحرف غير صالحة'),
      findsOneWidget,
    );
    expect(gateway.registration, isNull);
  });

  testWidgets('shows a localized error when registration email is in use', (
    tester,
  ) async {
    final gateway = _LoginGateway(
      isNewUser: true,
      registrationError: const ApiException(
        'Registration could not be completed.',
        statusCode: 409,
      ),
    );
    final controller = _controller(gateway);
    await tester.pumpWidget(_LoginTestApp(controller: controller));
    await tester.tap(find.byKey(const ValueKey('open-login')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('login-phone')),
      '0512345678',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('registration-name')),
      'مستخدم ثريا',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-email')),
      'x@x.com',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('registration-submit')),
    );
    await tester.tap(find.byKey(const ValueKey('registration-submit')));
    await tester.pump();

    expect(find.text('البريد الإلكتروني مستخدم بالفعل'), findsOneWidget);
    expect(find.text('Registration could not be completed.'), findsNothing);
    expect(find.byKey(const ValueKey('login-page')), findsOneWidget);
  });
}

AuthSessionController _controller(_LoginGateway gateway) {
  return AuthSessionController(
    authGateway: gateway,
    sessionStore: _LoginSessionStore(),
    now: () => DateTime.utc(2026, 9, 8, 12),
  );
}

class _LoginTestApp extends StatelessWidget {
  const _LoginTestApp({required this.controller});

  final AuthSessionController controller;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: controller,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const ValueKey('open-login'),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouteNames.login),
              child: const Text('Open'),
            ),
          ),
        ),
        onGenerateRoute: (settings) => MaterialPageRoute<bool>(
          builder: (_) => const LoginPage(),
          settings: settings,
        ),
      ),
    );
  }
}

class _LoginGateway implements AuthGateway {
  _LoginGateway({required this.isNewUser, this.registrationError});

  final bool isNewUser;
  final ApiException? registrationError;
  final List<String> loggedInPhones = [];
  (String, String, String)? registration;

  AuthResponse get _authenticatedResponse => AuthResponse(
    isNewUser: false,
    user: const AuthUser(
      id: 11,
      name: 'مستخدم ثريا',
      email: 'new@example.com',
      phoneNumber: '+966511111111',
      role: 'User',
    ),
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAtUtc: DateTime.utc(2026, 9, 8, 12, 15),
    refreshTokenExpiresAtUtc: DateTime.utc(2026, 10, 8, 12),
  );

  @override
  Future<AuthResponse> loginWithPhone(String phoneNumber) async {
    loggedInPhones.add(phoneNumber);
    if (!isNewUser) {
      return _authenticatedResponse;
    }
    return const AuthResponse(
      isNewUser: true,
      user: null,
      accessToken: null,
      refreshToken: null,
      accessTokenExpiresAtUtc: null,
      refreshTokenExpiresAtUtc: null,
    );
  }

  @override
  Future<AuthResponse> completeRegistration({
    required String phoneNumber,
    required String name,
    required String email,
  }) async {
    if (registrationError != null) {
      throw registrationError!;
    }
    registration = (phoneNumber, name, email);
    return _authenticatedResponse;
  }

  @override
  Future<AuthResponse> refresh(String refreshToken) async {
    return _authenticatedResponse;
  }

  @override
  Future<void> logout(String refreshToken) async {}
}

class _LoginSessionStore implements AuthSessionStore {
  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}
