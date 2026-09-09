import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_map_preview_card.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

import '../../../fixtures/restaurant_details_fixture.dart';

void main() {
  testWidgets('shows API image, RTL content, and both real rating types', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_card(_details)));
    await tester.pump();

    expect(find.text('مائدة الرياض'), findsOneWidget);
    expect(find.text('مطعم سعودي عصري.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('restaurant-preview-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-preview-thuraya-rating')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-preview-user-rating')),
      findsOneWidget,
    );
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('(8)'), findsOneWidget);
    expect(find.text('5 د'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides unavailable ratings and uses the Thuraya fallback image', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_card(_detailsWithoutRatings)));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('restaurant-preview-image-fallback')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-preview-thuraya-rating')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('restaurant-preview-user-rating')),
      findsNothing,
    );
    expect(find.byType(Divider), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(find.text('0.0'), findsNothing);
    expect(find.text('(0)'), findsNothing);
  });

  testWidgets('favorite action does not trigger details navigation', (
    tester,
  ) async {
    var openCount = 0;
    var favoriteCount = 0;
    await tester.pumpWidget(
      _testApp(
        RestaurantMapPreviewCard(
          restaurant: _details,
          isFavorite: false,
          isUpdatingFavorite: false,
          onTap: () => openCount++,
          onFavoriteTap: () => favoriteCount++,
          onClose: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-favorite')));
    await tester.pump();

    expect(favoriteCount, 1);
    expect(openCount, 0);

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-card')));
    await tester.pump();
    expect(openCount, 1);
  });

  testWidgets('close action remains independent from card navigation', (
    tester,
  ) async {
    var openCount = 0;
    var closeCount = 0;
    await tester.pumpWidget(
      _testApp(
        RestaurantMapPreviewCard(
          restaurant: _details,
          isFavorite: true,
          isUpdatingFavorite: false,
          onTap: () => openCount++,
          onFavoriteTap: () {},
          onClose: () => closeCount++,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-close')));
    await tester.pump();

    expect(closeCount, 1);
    expect(openCount, 0);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });
}

final RestaurantDetailsDto _details = RestaurantDetailsDto.fromJson(
  restaurantDetailsData,
);

final RestaurantDetailsDto _detailsWithoutRatings =
    RestaurantDetailsDto.fromJson({
      ...restaurantDetailsData,
      'photos': <Object>[],
      'reviewSummary': {
        ...(restaurantDetailsData['reviewSummary']! as Map<String, dynamic>),
        'userRatingAverage': null,
        'reviewCount': 0,
      },
      'thurayaReviewSummary': {
        ...(restaurantDetailsData['thurayaReviewSummary']!
            as Map<String, dynamic>),
        'averageRating': null,
        'totalReviews': 0,
        'latestReview': null,
        'history': <Object>[],
      },
      'isFavorite': false,
    });

RestaurantMapPreviewCard _card(RestaurantDetailsDto details) {
  return RestaurantMapPreviewCard(
    restaurant: details,
    isFavorite: details.isFavorite,
    isUpdatingFavorite: false,
    onTap: () {},
    onFavoriteTap: () {},
    onClose: () {},
  );
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Center(child: SizedBox(width: 390, child: child)),
    ),
  );
}
