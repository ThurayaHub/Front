import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/auth_service.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/auth/auth_session_store.dart';
import 'package:thuraya/core/auth/models/auth_models.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/features/account/models/profile_models.dart';
import 'package:thuraya/features/account/presentation/account_page.dart';
import 'package:thuraya/features/account/presentation/profile_controllers.dart';
import 'package:thuraya/features/account/presentation/profile_details_page.dart';
import 'package:thuraya/features/account/presentation/profile_favorites_page.dart';
import 'package:thuraya/features/account/presentation/profile_reviews_page.dart';
import 'package:thuraya/features/account/services/profile_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('account summary is Arabic, useful, and never exposes UserId', (
    tester,
  ) async {
    final gateway = _ProfileGateway();
    final auth = await _authenticatedController();
    await tester.pumpWidget(
      _ProfileTestApp(
        auth: auth,
        child: AccountPage(
          controller: AccountSummaryController(gateway: gateway),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('account-summary')), findsOneWidget);
    expect(find.text('سارة محمد'), findsOneWidget);
    expect(find.text('البريد الإلكتروني موثق'), findsOneWidget);
    expect(find.text('3 مراجعة'), findsOneWidget);
    expect(find.text('بياناتي'), findsOneWidget);
    expect(find.text('مفضلاتي'), findsOneWidget);
    expect(find.text('مراجعاتي'), findsOneWidget);
    expect(find.text('917'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('سارة محمد'))),
      TextDirection.rtl,
    );
  });

  testWidgets('details displays friendly optional data and membership year', (
    tester,
  ) async {
    final auth = await _authenticatedController();
    await tester.pumpWidget(
      _ProfileTestApp(
        auth: auth,
        child: ProfileDetailsPage(
          controller: ProfileDetailsController(gateway: _ProfileGateway()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-details-content')),
      findsOneWidget,
    );
    expect(find.text('سارة محمد'), findsOneWidget);
    expect(find.text('عضو منذ 2024'), findsOneWidget);
    expect(find.text('917'), findsNothing);
    expect(find.textContaining('2024-'), findsNothing);
  });

  testWidgets('favorites use real fields and removal executes once', (
    tester,
  ) async {
    final gateway = _ProfileGateway();
    final removedIds = <int>[];
    final auth = await _authenticatedController();
    await tester.pumpWidget(
      _ProfileTestApp(
        auth: auth,
        child: ProfileFavoritesPage(
          controller: FavoritesController(
            gateway: gateway,
            favoriteRemover: (id) async => removedIds.add(id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مائدة الرياض'), findsOneWidget);
    expect(find.text('نجمة ثريا'), findsOneWidget);
    expect(find.text('4.0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('favorite-42')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('restaurant-details-test-page')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('favorite-remove-42')));
    await tester.pumpAndSettle();

    expect(removedIds, [42]);
    expect(find.byKey(const ValueKey('favorites-empty')), findsOneWidget);
  });

  testWidgets('reviews show restaurant, normalized rating, comment, and date', (
    tester,
  ) async {
    final auth = await _authenticatedController();
    await tester.pumpWidget(
      _ProfileTestApp(
        auth: auth,
        child: ProfileReviewsPage(
          controller: ReviewsController(gateway: _ProfileGateway()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-reviews-list')), findsOneWidget);
    expect(find.text('مائدة الرياض'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('تجربة جميلة وخدمة ممتازة'), findsOneWidget);
    expect(find.text('502'), findsNothing);
  });
}

Future<AuthSessionController> _authenticatedController() async {
  final now = DateTime.utc(2026, 9, 9, 12);
  final session = AuthSession(
    user: const AuthUser(
      id: 917,
      name: 'سارة محمد',
      email: 'sara@example.com',
      phoneNumber: '+966500000000',
      role: 'User',
    ),
    accessToken: 'access',
    refreshToken: 'refresh',
    accessTokenExpiresAtUtc: now.add(const Duration(hours: 1)),
    refreshTokenExpiresAtUtc: now.add(const Duration(days: 30)),
  );
  final controller = AuthSessionController(
    authGateway: _AuthGateway(),
    sessionStore: _SessionStore(session),
    now: () => now,
  );
  await controller.restoreSession();
  return controller;
}

class _ProfileTestApp extends StatelessWidget {
  const _ProfileTestApp({required this.auth, required this.child});

  final AuthSessionController auth;
  final Widget child;

  @override
  Widget build(BuildContext context) => AuthScope(
    controller: auth,
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
      onGenerateRoute: (settings) {
        if (settings.name == AppRouteNames.restaurantDetails) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(key: ValueKey('restaurant-details-test-page')),
            settings: settings,
          );
        }
        return null;
      },
    ),
  );
}

class _ProfileGateway implements ProfileGateway {
  @override
  Future<ProfileSummaryDto> getSummary() async => const ProfileSummaryDto(
    userId: 917,
    name: 'سارة محمد',
    phoneNumber: '+966500000000',
    email: 'sara@example.com',
    isEmailVerified: true,
    reviewCount: 3,
  );

  @override
  Future<UserProfileDto> getDetails() async => UserProfileDto(
    userId: 917,
    name: 'سارة محمد',
    phoneNumber: null,
    email: 'sara@example.com',
    isEmailVerified: true,
    createdAtUtc: DateTime.utc(2024, 3, 2),
    emailVerifiedAtUtc: DateTime.utc(2024, 3, 3),
  );

  @override
  Future<List<ProfileFavoriteRestaurantDto>> getFavorites() async => const [
    ProfileFavoriteRestaurantDto(
      restaurantId: 42,
      nameEn: 'Riyadh Table',
      nameAr: 'مائدة الرياض',
      mainPhotoUrl: null,
      userRatingAverage: 4,
      priceLevelId: 2,
      priceLevelName: 'Medium',
      neighborhoodId: 7,
      neighborhoodNameAr: 'العليا',
      neighborhoodNameEn: 'Olaya',
      hasThurayaStar: true,
    ),
  ];

  @override
  Future<List<ProfileReviewDto>> getReviews() async => [
    ProfileReviewDto(
      reviewId: 502,
      restaurantId: 42,
      restaurantNameEn: 'Riyadh Table',
      restaurantNameAr: 'مائدة الرياض',
      restaurantMainPhotoUrl: null,
      rating: 5,
      comment: 'تجربة جميلة وخدمة ممتازة',
      createdAtUtc: DateTime.utc(2026, 9, 1),
      updatedAtUtc: null,
    ),
  ];
}

class _SessionStore implements AuthSessionStore {
  _SessionStore(this.session);
  AuthSession? session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}

class _AuthGateway implements AuthGateway {
  @override
  Future<AuthResponse> completeRegistration({
    required String phoneNumber,
    required String name,
    required String email,
  }) => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithPhone(String phoneNumber) =>
      throw UnimplementedError();

  @override
  Future<void> logout(String refreshToken) async {}

  @override
  Future<AuthResponse> refresh(String refreshToken) =>
      throw UnimplementedError();
}
