import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/core/widgets/rating_stars.dart';
import 'package:thuraya/features/restaurant_reviews/models/restaurant_reviews_data.dart';
import 'package:thuraya/features/restaurant_reviews/presentation/restaurant_reviews_page.dart';
import 'package:thuraya/features/restaurant_reviews/services/restaurant_review_service.dart';
import 'package:thuraya/features/restaurants/models/restaurant_review.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('keeps summary and displays all returned reviews', (tester) async {
    final reviews = <RestaurantReview>[
      _review(1, 5, 'ممتاز جداً', 'محمد أحمد'),
      _review(2, 4, null, 'سارة'),
      _review(3, 3, '', 'عبدالله'),
      _review(4, 2, '   ', 'English Reviewer'),
    ];
    final service = _TestReviewService((_) async => reviews);

    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();

    expect(find.text('مطعم الاختبار'), findsOneWidget);
    expect(find.text('3.0'), findsOneWidget);
    expect(find.text('4 تقييم'), findsOneWidget);
    expect(find.byKey(const ValueKey('review-card-1')), findsOneWidget);
    expect(find.text('ممتاز جداً'), findsOneWidget);

    expect(find.byKey(const ValueKey('review-comment-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('review-comment-2')), findsNothing);
    expect(find.byKey(const ValueKey('review-comment-3')), findsNothing);

    final stars = tester.widget<RatingStars>(
      find.descendant(
        of: find.byKey(const ValueKey('review-card-1')),
        matching: find.byType(RatingStars),
      ),
    );
    expect(stars.rating, 5);
    expect(stars.maxStars, 5);

    for (final id in [2, 3, 4]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('review-card-$id')),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.byKey(ValueKey('review-card-$id')), findsOneWidget);
      expect(find.byKey(ValueKey('review-comment-$id')), findsNothing);
    }
    expect(find.text('English Reviewer'), findsOneWidget);
    expect(service.requests, [42]);
  });

  testWidgets('shows loading before the API request completes', (tester) async {
    final response = Completer<List<RestaurantReview>>();
    final service = _TestReviewService((_) => response.future);

    await tester.pumpWidget(_app(service: service));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('restaurant-reviews-loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-reviews-empty')),
      findsNothing,
    );

    response.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('shows a friendly empty state after an empty response', (
    tester,
  ) async {
    final service = _TestReviewService((_) async => const []);

    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('restaurant-reviews-empty')),
      findsOneWidget,
    );
    expect(find.text('لا توجد تقييمات حتى الآن'), findsOneWidget);
    expect(find.textContaining('غير متاحة من الخادم'), findsNothing);
  });

  testWidgets('keeps the summary visible and retries a failed list request', (
    tester,
  ) async {
    var attempts = 0;
    final service = _TestReviewService((_) async {
      attempts++;
      if (attempts == 1) throw Exception('temporary failure');
      return [_review(9, 4, null, 'سارة')];
    });

    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();

    expect(find.text('3.0'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('restaurant-reviews-error')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('restaurant-reviews-retry')),
    );
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byKey(const ValueKey('review-card-9')), findsOneWidget);
  });

  testWidgets('many reviews scroll without overflow', (tester) async {
    final reviews = List.generate(
      24,
      (index) => _review(
        index + 1,
        (index % 5) + 1,
        index.isEven ? 'تعليق رقم $index' : null,
        'Reviewer $index',
      ),
    );
    final service = _TestReviewService((_) async => reviews);

    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('review-card-24')),
      500,
      scrollable: find.byType(Scrollable),
    );

    expect(find.byKey(const ValueKey('review-card-24')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({required RestaurantReviewService service}) {
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
    home: RestaurantReviewsPage.fromData(
      data: const RestaurantReviewsData(
        restaurantId: 42,
        restaurantName: 'مطعم الاختبار',
        rating: 3,
        reviewCount: 4,
        reviews: [],
        hasReviewList: false,
      ),
      reviewService: service,
    ),
  );
}

RestaurantReview _review(
  int id,
  int stars,
  String? comment,
  String reviewerName,
) {
  return RestaurantReview(
    id: id,
    restaurantId: 42,
    reviewerName: reviewerName,
    stars: stars,
    comment: comment,
    createdAtUtc: DateTime.utc(2026, 9, 12),
  );
}

class _TestReviewService extends RestaurantReviewService {
  _TestReviewService(this.loader);

  final Future<List<RestaurantReview>> Function(int restaurantId) loader;
  final List<int> requests = [];

  @override
  Future<List<RestaurantReview>> getReviews(int restaurantId) {
    requests.add(restaurantId);
    return loader(restaurantId);
  }
}
