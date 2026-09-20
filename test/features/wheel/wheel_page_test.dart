import 'dart:async';
import 'dart:math' as math;

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
import 'package:thuraya/core/routing/app_router.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/core/widgets/thuraya_bottom_navigation_bar.dart';
import 'package:thuraya/features/wheel/models/wheel_models.dart';
import 'package:thuraya/features/wheel/presentation/wheel_page.dart';
import 'package:thuraya/features/wheel/presentation/widgets/dynamic_wheel.dart';
import 'package:thuraya/features/wheel/services/wheel_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('login continues to Wheel and backend winner drives animation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _authController();
    final gateway = _PageWheelGateway();

    await tester.pumpWidget(_wheelFlowApp(auth, gateway));
    await tester.tap(find.byKey(const ValueKey('navigation-wheel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login-page')), findsOneWidget);
    expect(gateway.createCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('login-phone')),
      '+966500000000',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('wheel-page')), findsOneWidget);
    expect(gateway.createCalls, 1);
    expect(gateway.options, isEmpty);
    expect(find.byKey(const ValueKey('wheel-empty-state')), findsOneWidget);
    expect(find.text('برجر'), findsNothing);
    expect(find.text('بيتزا'), findsNothing);
    expect(find.text('سوشي'), findsNothing);
    expect(find.text('قهوة'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('wheel-option-input')),
      '  شاي  ',
    );
    await tester.tap(find.byKey(const ValueKey('wheel-add-option')));
    await tester.pumpAndSettle();
    expect(gateway.options.last.text, 'شاي');
    expect(gateway.options.last.id, 100);

    await tester.enterText(
      find.byKey(const ValueKey('wheel-option-input')),
      'قهوة',
    );
    await tester.tap(find.byKey(const ValueKey('wheel-add-option')));
    await tester.pumpAndSettle();

    gateway.spinCompleter = Completer();
    final spinButton = find.byKey(const ValueKey('wheel-spin-button'));
    await tester.ensureVisible(spinButton);
    await tester.pumpAndSettle();
    await tester.tap(spinButton);
    await tester.tap(find.byKey(const ValueKey('wheel-spin-button')));
    await tester.pump();
    expect(gateway.spinCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gateway.spinCompleter!.complete(gateway.resultFor(gateway.options[1]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3700));
    await tester.pumpAndSettle();

    expect(find.text('اختيارك هو'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('wheel-result-value')))
          .data,
      gateway.options[1].text,
    );
    final wheel = tester.widget<DynamicWheel>(find.byType(DynamicWheel));
    final normalized =
        (wheel.rotation % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final expected =
        (-(1.5) * (2 * math.pi / 2) % (2 * math.pi) + 2 * math.pi) %
        (2 * math.pi);
    expect(normalized, closeTo(expected, 0.0001));
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets('Wheel follows ${locale.languageCode} direction', (
      tester,
    ) async {
      final auth = _authController();
      await auth.loginWithPhone('+966500000000');
      await tester.pumpWidget(
        _pageApp(auth, _PageWheelGateway(), locale: locale),
      );
      await tester.pumpAndSettle();

      final title = find.text(
        locale.languageCode == 'ar'
            ? 'محتار؟ خلها علينا'
            : 'Not sure? Leave it to us',
      );
      expect(
        Directionality.of(tester.element(title)),
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }

  testWidgets('removes an option through its chip and redraws the wheel', (
    tester,
  ) async {
    final auth = _authController();
    await auth.loginWithPhone('+966500000000');
    final gateway = _PageWheelGateway(initialOptions: const ['برجر', 'بيتزا']);
    await tester.pumpWidget(
      _pageApp(auth, gateway, locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();

    final burgerChip = find.byKey(const ValueKey('wheel-option-100'));
    await tester.tap(
      find.descendant(
        of: burgerChip,
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    await tester.pumpAndSettle();

    expect(gateway.removeCalls, 1);
    expect(gateway.options.first.isActive, isFalse);
    expect(find.byKey(const ValueKey('wheel-option-count-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('wheel-option-100')), findsNothing);
  });

  testWidgets('shows a localized backend error and keeps wheel options', (
    tester,
  ) async {
    final auth = _authController();
    await auth.loginWithPhone('+966500000000');
    final gateway = _PageWheelGateway(initialOptions: const ['أ', 'ب'])
      ..spinError = const ApiException('Forbidden', statusCode: 403);
    await tester.pumpWidget(
      _pageApp(auth, gateway, locale: const Locale('ar')),
    );
    await tester.pumpAndSettle();

    final spinButton = find.byKey(const ValueKey('wheel-spin-button'));
    await tester.ensureVisible(spinButton);
    await tester.pumpAndSettle();
    await tester.tap(spinButton);
    await tester.pumpAndSettle();

    expect(
      find.text('ليس لديك صلاحية للوصول إلى جلسة العجلة هذه.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('wheel-option-count-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('wheel-result')), findsNothing);
  });
}

Widget _wheelFlowApp(AuthSessionController auth, _PageWheelGateway gateway) {
  return AuthScope(
    controller: auth,
    child: MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: _delegates,
      home: const Scaffold(
        bottomNavigationBar: ThurayaBottomNavigationBar(
          selectedTab: ThurayaNavigationTab.home,
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == AppRouteNames.wheel) {
          return MaterialPageRoute<void>(
            builder: (_) => WheelPage(gateway: gateway),
            settings: settings,
          );
        }
        return AppRouter.onGenerateRoute(settings);
      },
    ),
  );
}

Widget _pageApp(
  AuthSessionController auth,
  _PageWheelGateway gateway, {
  required Locale locale,
}) {
  return AuthScope(
    controller: auth,
    child: MaterialApp(
      locale: locale,
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: _delegates,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: WheelPage(gateway: gateway),
    ),
  );
}

const _delegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class _PageWheelGateway implements WheelGateway {
  _PageWheelGateway({List<String> initialOptions = const []}) {
    for (final text in initialOptions) {
      options.add(WheelOptionDto(id: nextId++, text: text, isActive: true));
    }
    sessionExists = initialOptions.isNotEmpty;
  }

  bool sessionExists = false;
  int createCalls = 0;
  int removeCalls = 0;
  int spinCalls = 0;
  int nextId = 100;
  Completer<WheelSpinResultDto>? spinCompleter;
  ApiException? spinError;
  final List<WheelOptionDto> options = [];

  @override
  Future<WheelSessionDto> createSession({String? name}) async {
    createCalls++;
    sessionExists = true;
    return _session();
  }

  @override
  Future<WheelSessionDto> getCurrentSession() async {
    if (!sessionExists) {
      throw const ApiException('Not found', statusCode: 404);
    }
    return _session();
  }

  @override
  Future<WheelSessionDto> getSession(int wheelSessionId) async => _session();

  @override
  Future<WheelOptionDto> addOption(int wheelSessionId, String text) async {
    final option = WheelOptionDto(id: nextId++, text: text, isActive: true);
    options.add(option);
    return option;
  }

  @override
  Future<WheelOptionDto> removeOption(int wheelSessionId, int optionId) async {
    removeCalls++;
    final index = options.indexWhere((option) => option.id == optionId);
    final removed = WheelOptionDto(
      id: options[index].id,
      text: options[index].text,
      isActive: false,
    );
    options[index] = removed;
    return removed;
  }

  @override
  Future<WheelSpinResultDto> spin(int wheelSessionId) {
    spinCalls++;
    if (spinError case final error?) return Future.error(error);
    return spinCompleter?.future ?? Future.value(resultFor(options[1]));
  }

  WheelSpinResultDto resultFor(WheelOptionDto option) => WheelSpinResultDto(
    id: 500,
    wheelSessionId: 20,
    selectedOption: option,
    createdAtUtc: DateTime.utc(2026, 9, 20),
  );

  WheelSessionDto _session() => WheelSessionDto(
    id: 20,
    name: null,
    options: List.unmodifiable(options),
    createdAtUtc: DateTime.utc(2026, 9, 20),
    updatedAtUtc: null,
  );
}

AuthSessionController _authController() => AuthSessionController(
  authGateway: _WheelAuthGateway(),
  sessionStore: _WheelSessionStore(),
  now: () => DateTime.utc(2026, 9, 20, 12),
);

class _WheelAuthGateway implements AuthGateway {
  AuthResponse get _response => AuthResponse(
    isNewUser: false,
    user: const AuthUser(
      id: 1,
      name: 'User',
      email: 'user@example.com',
      phoneNumber: '+966500000000',
      role: 'User',
    ),
    accessToken: 'jwt',
    refreshToken: 'refresh',
    accessTokenExpiresAtUtc: DateTime.utc(2026, 9, 20, 13),
    refreshTokenExpiresAtUtc: DateTime.utc(2026, 10, 20),
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

class _WheelSessionStore implements AuthSessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}
}
