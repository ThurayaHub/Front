import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/presentation/restaurant_details_page.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

import '../../../fixtures/restaurant_details_fixture.dart';

void main() {
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
    expect(find.text('8 تقييم مستخدم'), findsOneWidget);
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

class _TestRestaurantDetailsService extends RestaurantDetailsService {
  _TestRestaurantDetailsService(this.loader);

  final Future<RestaurantDetailsDto> Function(int restaurantId) loader;

  @override
  Future<RestaurantDetailsDto> getDetails(int restaurantId) {
    return loader(restaurantId);
  }
}
