import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/auth/auth_scope.dart';
import 'package:thuraya/core/auth/auth_service.dart';
import 'package:thuraya/core/auth/auth_session_controller.dart';
import 'package:thuraya/core/auth/auth_session_store.dart';
import 'package:thuraya/core/auth/models/auth_models.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/routing/app_router.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/presentation/restaurant_details_page.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_external_actions.dart';
import 'package:thuraya/features/restaurant_reviews/services/restaurant_review_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

import '../../../fixtures/restaurant_details_fixture.dart';

void main() {
  testWidgets('preloaded map details open without a duplicate API load', (
    tester,
  ) async {
    await tester.pumpWidget(_testPreloadedApp());
    await tester.pump();

    expect(
      find.byKey(const ValueKey('restaurant-details-page')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-details-loading')),
      findsNothing,
    );
    expect(find.text('مائدة الرياض'), findsOneWidget);
  });

  testWidgets('uses the first photo as hero and only later photos in gallery', (
    tester,
  ) async {
    final details = RestaurantDetailsDto.fromJson({
      ...restaurantDetailsData,
      'photos': [
        {
          'id': 1,
          'url': 'assets/images/restaurant_details/cover.png',
          'caption': 'Hero',
          'displayOrder': 1,
          'isCoverPhoto': true,
        },
        {
          'id': 2,
          'url': 'assets/images/restaurant_details/gallery_food.jpeg',
          'caption': 'Food',
          'displayOrder': 2,
          'isCoverPhoto': false,
        },
        {
          'id': 3,
          'url': 'assets/images/restaurant_details/gallery_dining.jpeg',
          'caption': 'Dining',
          'displayOrder': 3,
          'isCoverPhoto': false,
        },
      ],
    });

    await tester.pumpWidget(_testPreloadedApp(details: details));
    await tester.pump();

    final hero = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('restaurant-details-hero-image')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (hero.image as AssetImage).assetName,
      'assets/images/restaurant_details/cover.png',
    );
    expect(
      find.byKey(const ValueKey('restaurant-gallery-image-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-gallery-image-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-gallery-image-2')),
      findsNothing,
    );
  });

  testWidgets('hides absent ratings and removes the Call action', (
    tester,
  ) async {
    final details = RestaurantDetailsDto.fromJson({
      ...restaurantDetailsData,
      'reviewSummary': {
        'userRatingAverage': null,
        'reviewCount': 0,
        'adminRatingAverage': null,
        'adminRatingCount': 0,
      },
      'thurayaReviewSummary': {
        'averageRating': null,
        'totalReviews': 0,
        'latestReview': null,
        'history': <Object>[],
      },
    });

    await tester.pumpWidget(_testPreloadedApp(details: details));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('restaurant-details-thuraya-rating')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('restaurant-details-reviews')),
      findsNothing,
    );
    expect(find.text('اتصال'), findsNothing);
    expect(find.text('الاتجاهات'), findsOneWidget);
    expect(find.text('مشاركة'), findsOneWidget);
  });

  testWidgets('Directions and Share receive the real details DTO', (
    tester,
  ) async {
    final actions = _TestExternalActions();
    await tester.pumpWidget(_testPreloadedApp(externalActions: actions));
    await tester.pump();

    final directions = find.byKey(
      const ValueKey('restaurant-details-directions'),
    );
    await tester.ensureVisible(directions);
    await tester.tap(directions);
    await tester.pump();
    final share = find.byKey(const ValueKey('restaurant-details-share'));
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.pump();

    expect(actions.directionsRestaurantId, 42);
    expect(actions.sharedRestaurantId, 42);
  });

  testWidgets('real review summary opens an honest unavailable-list state', (
    tester,
  ) async {
    await tester.pumpWidget(_testPreloadedApp());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('restaurant-details-reviews')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('restaurant-reviews-unavailable')),
      findsOneWidget,
    );
    expect(find.text('8 تقييم'), findsOneWidget);
  });

  testWidgets(
    'logged-out Favorite logs in then completes the API action once',
    (tester) async {
      final authController = _authController();
      final service = _FavoriteDetailsService();
      await tester.pumpWidget(
        _testPreloadedApp(
          authController: authController,
          detailsService: service,
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('restaurant-details-favorite')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('login-page')), findsOneWidget);
      expect(service.favoriteTargets, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('login-phone')),
        '+966500000000',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('login-page')), findsNothing);
      expect(service.detailsRequests, 1);
      expect(service.favoriteTargets, [true]);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'logged-out review logs in, submits once, and refreshes details',
    (tester) async {
      final authController = _authController();
      final detailsService = _ReviewDetailsService();
      final reviewService = _TestReviewService();
      await tester.pumpWidget(
        _testPreloadedApp(
          authController: authController,
          detailsService: detailsService,
          reviewService: reviewService,
        ),
      );
      await tester.pump();

      final writeReview = find.byKey(const ValueKey('restaurant-write-review'));
      await tester.ensureVisible(writeReview);
      await tester.tap(writeReview);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('login-page')), findsOneWidget);
      expect(reviewService.submissions, isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('login-phone')),
        '+966500000000',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('review-sheet-title')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('review-star-5')));
      await tester.enterText(
        find.byKey(const ValueKey('review-comment-field')),
        'تجربة ممتازة',
      );
      await tester.pump();
      final submit = find.byKey(const ValueKey('review-submit-button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(reviewService.submissions, [(42, 5, 'تجربة ممتازة')]);
      expect(detailsService.detailsRequests, 1);
      expect(find.text('تمت إضافة مراجعتك بنجاح'), findsOneWidget);
    },
  );

  testWidgets('ID-backed shared page shows loading then API details', (
    tester,
  ) async {
    final response = Completer<RestaurantDetailsDto>();
    final service = _TestRestaurantDetailsService((_) => response.future);
    addTearDown(service.close);

    await tester.pumpWidget(_testApp(service));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('restaurant-details-loading')),
      findsOneWidget,
    );

    response.complete(_detailsDto);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('restaurant-details-page')),
      findsOneWidget,
    );
    expect(find.text('مائدة الرياض'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('8 تقييم'), findsOneWidget);
    expect(find.textContaining('Saudi'), findsOneWidget);
  });

  testWidgets('ID-backed details error supports retry', (tester) async {
    var requestCount = 0;
    final retryResponse = Completer<RestaurantDetailsDto>();
    final service = _TestRestaurantDetailsService((_) async {
      requestCount++;
      if (requestCount == 1) {
        throw const ApiException('Failed.', statusCode: 500);
      }
      return retryResponse.future;
    });
    addTearDown(service.close);

    await tester.pumpWidget(_testApp(service));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('restaurant-details-error')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('restaurant-details-retry')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('restaurant-details-loading')),
      findsOneWidget,
    );
    retryResponse.complete(_detailsDto);
    await tester.pumpAndSettle();

    expect(requestCount, 2);
    expect(
      find.byKey(const ValueKey('restaurant-details-page')),
      findsOneWidget,
    );
  });
}

final RestaurantDetailsDto _detailsDto = RestaurantDetailsDto.fromJson(
  restaurantDetailsData,
);

Widget _testApp(RestaurantDetailsService service) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.light,
    home: RestaurantDetailsPage.fromId(
      restaurantId: 42,
      detailsService: service,
    ),
  );
}

Widget _testPreloadedApp({
  RestaurantDetailsDto? details,
  RestaurantExternalActions? externalActions,
  RestaurantDetailsService? detailsService,
  RestaurantReviewService? reviewService,
  AuthSessionController? authController,
}) {
  return AuthScope(
    controller: authController ?? _authController(),
    child: MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: RestaurantDetailsPage.fromDetails(
        details: details ?? _detailsDto,
        detailsService: detailsService,
        reviewService: reviewService,
        externalActions: externalActions,
      ),
    ),
  );
}

class _TestRestaurantDetailsService extends RestaurantDetailsService {
  _TestRestaurantDetailsService(this.loader);

  final Future<RestaurantDetailsDto> Function(int restaurantId) loader;

  @override
  Future<RestaurantDetailsDto> getDetails(int restaurantId) {
    return loader(restaurantId);
  }
}

class _TestExternalActions extends RestaurantExternalActions {
  int? directionsRestaurantId;
  int? sharedRestaurantId;

  @override
  Future<bool> openDirections(RestaurantDetailsDto restaurant) async {
    directionsRestaurantId = restaurant.id;
    return true;
  }

  @override
  Future<void> shareRestaurant(
    RestaurantDetailsDto restaurant, {
    Rect? sharePositionOrigin,
  }) async {
    sharedRestaurantId = restaurant.id;
  }
}

class _FavoriteDetailsService extends RestaurantDetailsService {
  int detailsRequests = 0;
  final List<bool> favoriteTargets = [];

  @override
  Future<RestaurantDetailsDto> getDetails(int restaurantId) async {
    detailsRequests++;
    return RestaurantDetailsDto.fromJson({
      ...restaurantDetailsData,
      'isFavorite': false,
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

class _ReviewDetailsService extends RestaurantDetailsService {
  int detailsRequests = 0;

  @override
  Future<RestaurantDetailsDto> getDetails(int restaurantId) async {
    detailsRequests++;
    return _detailsDto;
  }
}

class _TestReviewService extends RestaurantReviewService {
  final List<(int, int, String)> submissions = [];

  @override
  Future<void> createReview({
    required int restaurantId,
    required int stars,
    required String comment,
  }) async {
    submissions.add((restaurantId, stars, comment));
  }
}

AuthSessionController _authController() {
  return AuthSessionController(
    authGateway: _DetailsAuthGateway(),
    sessionStore: _DetailsSessionStore(),
    now: () => DateTime.utc(2026, 9, 8, 12),
  );
}

class _DetailsAuthGateway implements AuthGateway {
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

class _DetailsSessionStore implements AuthSessionStore {
  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}

  @override
  Future<void> clear() async {}
}
