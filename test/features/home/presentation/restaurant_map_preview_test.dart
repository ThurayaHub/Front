import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/auth_service.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/auth/auth_session_store.dart';
import 'package:thuraya/core/auth/models/auth_models.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_map_preview.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

import '../../../fixtures/restaurant_details_fixture.dart';

void main() {
  testWidgets('loads real details after marker selection', (tester) async {
    final service = _PreviewDetailsService();
    final controller = _authController();
    RestaurantDetailsDto? openedDetails;

    await tester.pumpWidget(
      _previewApp(
        service: service,
        authController: controller,
        onDetailsTap: (details) => openedDetails = details,
      ),
    );

    expect(
      find.byKey(const ValueKey('restaurant-preview-loading')),
      findsOneWidget,
    );
    expect(find.text('مائدة الرياض'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('مائدة الرياض'), findsOneWidget);
    expect(find.text('مطعم سعودي عصري.'), findsOneWidget);
    expect(service.detailsRequests, 1);

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-card')));
    await tester.pump();
    expect(openedDetails?.id, 42);
    expect(service.detailsRequests, 1);
  });

  testWidgets('login returns to the map and completes favorite exactly once', (
    tester,
  ) async {
    final service = _PreviewDetailsService();
    final controller = _authController();
    await tester.pumpWidget(
      _previewApp(service: service, authController: controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-favorite')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('preview-test-login')), findsOneWidget);
    expect(service.favoriteTargets, isEmpty);

    await tester.tap(find.byKey(const ValueKey('preview-test-login-success')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('preview-test-login')), findsNothing);
    expect(service.detailsRequests, 2);
    expect(service.favoriteTargets, [true]);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('cancelling login leaves favorite unchanged', (tester) async {
    final service = _PreviewDetailsService();
    final controller = _authController();
    await tester.pumpWidget(
      _previewApp(service: service, authController: controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-favorite')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preview-test-login-cancel')));
    await tester.pumpAndSettle();

    expect(controller.isAuthenticated, isFalse);
    expect(service.favoriteTargets, isEmpty);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });
}

Widget _previewApp({
  required _PreviewDetailsService service,
  required AuthSessionController authController,
  ValueChanged<RestaurantDetailsDto>? onDetailsTap,
}) {
  return AuthScope(
    controller: authController,
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: RestaurantMapPreview(
              restaurant: _marker,
              detailsService: service,
              onTap: onDetailsTap ?? (_) {},
              onClose: () {},
            ),
          ),
        ),
      ),
      routes: {
        AppRouteNames.login: (context) => Scaffold(
          key: const ValueKey('preview-test-login'),
          body: Column(
            children: [
              TextButton(
                key: const ValueKey('preview-test-login-success'),
                onPressed: () async {
                  await authController.loginWithPhone('+966500000000');
                  if (context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Login'),
              ),
              TextButton(
                key: const ValueKey('preview-test-login-cancel'),
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

class _PreviewDetailsService extends RestaurantDetailsService {
  int detailsRequests = 0;
  final List<bool> favoriteTargets = [];

  @override
  Future<RestaurantDetailsDto> getDetails(int restaurantId) async {
    detailsRequests++;
    return RestaurantDetailsDto.fromJson({
      ...restaurantDetailsData,
      'isFavorite': detailsRequests == 1 ? null : false,
    });
  }

  @override
  Future<RestaurantFavoriteDto> setFavorite(
    int restaurantId, {
    required bool isFavorite,
  }) async {
    favoriteTargets.add(isFavorite);
    return RestaurantFavoriteDto(
      restaurantId: restaurantId,
      userId: 1,
      isFavorite: isFavorite,
    );
  }
}

AuthSessionController _authController() {
  return AuthSessionController(
    authGateway: _PreviewAuthGateway(),
    sessionStore: _PreviewSessionStore(),
    now: () => DateTime.utc(2026, 9, 8, 12),
  );
}

class _PreviewAuthGateway implements AuthGateway {
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

class _PreviewSessionStore implements AuthSessionStore {
  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}

const RestaurantMapMarker _marker = RestaurantMapMarker(
  id: 42,
  name: 'Riyadh Table',
  nameArabic: 'مائدة الرياض',
  latitude: 24.7136,
  longitude: 46.6753,
  priceLevelId: 3,
  hasThurayaStar: true,
  userRatingAverage: 4.5,
  reviewCount: 8,
  mainPhotoUrl: null,
  primaryCategoryId: 9,
  primaryCategoryName: 'Saudi',
);
