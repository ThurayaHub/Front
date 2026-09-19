import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';
import 'package:thuraya/features/trending/models/trending_restaurant_dto.dart';
import 'package:thuraya/features/trending/presentation/trending_controller.dart';
import 'package:thuraya/features/trending/presentation/trending_page.dart';
import 'package:thuraya/features/trending/services/trending_restaurant_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('renders backend ranks and lookup metadata in Arabic RTL', (
    tester,
  ) async {
    final controller = _controller([
      _restaurant(
        id: 70,
        rank: 7,
        name: 'Riyadh Table',
        description: 'مطعم عصري في قلب الرياض',
        hasStar: true,
      ),
      _restaurant(id: 20, rank: 2, name: 'Second Restaurant'),
    ]);
    addTearDown(controller.dispose);
    Object? routeArgument;

    await tester.pumpWidget(
      _testApp(controller, onDetails: (argument) => routeArgument = argument),
    );
    await tester.pumpAndSettle();

    final title = find.text('الترند');
    expect(title, findsNWidgets(2));
    expect(Directionality.of(tester.element(title.first)), TextDirection.rtl);
    expect(find.text('المطاعم الأكثر رواجاً'), findsOneWidget);
    expect(find.text('#7'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.byKey(const ValueKey('trending-rank-1')), findsNothing);
    expect(find.text(r'$$  •  سعودي  •  العليا'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('trending-star-70')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trending-card-70')));
    await tester.pumpAndSettle();
    expect(routeArgument, 70);
    expect(find.byKey(const ValueKey('details-placeholder')), findsOneWidget);
  });

  testWidgets('renders English content in LTR', (tester) async {
    final controller = _controller([
      _restaurant(id: 42, rank: 1, name: 'Riyadh Table'),
    ]);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_testApp(controller, locale: const Locale('en')));
    await tester.pumpAndSettle();

    final title = find.text('Trending');
    expect(title, findsNWidgets(2));
    expect(Directionality.of(tester.element(title.first)), TextDirection.ltr);
    expect(find.text('Trending restaurants'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text(r'$$  •  Saudi  •  Al Olaya'), findsOneWidget);
  });

  testWidgets('shows loading, empty, and pull-to-refresh states', (
    tester,
  ) async {
    final response = Completer<List<TrendingRestaurantDto>>();
    final gateway = _SequenceTrendingGateway([
      response.future,
      Future.value([]),
    ]);
    final controller = TrendingController(
      trendingGateway: gateway,
      lookupGateway: _LookupGateway(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_testApp(controller));
    await tester.pump();
    expect(find.byKey(const ValueKey('trending-loading')), findsOneWidget);

    response.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('لا توجد مطاعم في الترند حالياً'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('trending-empty')),
      const Offset(0, 350),
    );
    await tester.pumpAndSettle();
    expect(gateway.calls, 2);
  });

  testWidgets('shows an error and retries successfully', (tester) async {
    final gateway = _FailThenSucceedTrendingGateway([
      _restaurant(id: 9, rank: 4, name: 'Recovered'),
    ]);
    final controller = TrendingController(
      trendingGateway: gateway,
      lookupGateway: _LookupGateway(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_testApp(controller));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trending-error')), findsOneWidget);
    expect(find.text('تعذر تحميل مطاعم الترند حالياً'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trending-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Recovered'), findsOneWidget);
    expect(find.text('#4'), findsOneWidget);
  });
}

Widget _testApp(
  TrendingController controller, {
  Locale locale = const Locale('ar'),
  ValueChanged<Object?>? onDetails,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: TrendingPage(controller: controller),
    onGenerateRoute: (settings) {
      if (settings.name == AppRouteNames.restaurantDetails) {
        onDetails?.call(settings.arguments);
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(key: ValueKey('details-placeholder')),
          settings: settings,
        );
      }
      return MaterialPageRoute<void>(builder: (_) => const SizedBox());
    },
  );
}

TrendingController _controller(List<TrendingRestaurantDto> restaurants) {
  return TrendingController(
    trendingGateway: _StaticTrendingGateway(restaurants),
    lookupGateway: _LookupGateway(),
  );
}

class _StaticTrendingGateway implements TrendingRestaurantGateway {
  const _StaticTrendingGateway(this.restaurants);

  final List<TrendingRestaurantDto> restaurants;

  @override
  Future<List<TrendingRestaurantDto>> getTrending() async => restaurants;
}

class _SequenceTrendingGateway implements TrendingRestaurantGateway {
  _SequenceTrendingGateway(this.responses);

  final List<Future<List<TrendingRestaurantDto>>> responses;
  int calls = 0;

  @override
  Future<List<TrendingRestaurantDto>> getTrending() {
    final response = responses[calls.clamp(0, responses.length - 1)];
    calls++;
    return response;
  }
}

class _FailThenSucceedTrendingGateway implements TrendingRestaurantGateway {
  _FailThenSucceedTrendingGateway(this.restaurants);

  final List<TrendingRestaurantDto> restaurants;
  int calls = 0;

  @override
  Future<List<TrendingRestaurantDto>> getTrending() async {
    calls++;
    if (calls == 1) throw StateError('offline');
    return restaurants;
  }
}

class _LookupGateway implements RestaurantLookupGateway {
  @override
  Future<List<RestaurantLookupItemDto>> getPriceLevels() async => const [
    RestaurantLookupItemDto(id: 2, name: 'Medium', description: null),
  ];

  @override
  Future<List<RestaurantLookupItemDto>> getCategories() async => const [
    RestaurantLookupItemDto(id: 5, name: 'Saudi', description: null),
  ];

  @override
  Future<List<NeighborhoodLookupDto>> getNeighborhoods() async => const [
    NeighborhoodLookupDto(
      id: 31,
      nameAr: 'العليا',
      nameEn: 'Al Olaya',
      cityAr: 'الرياض',
      cityEn: 'Riyadh',
      countryCode: 'SA',
    ),
  ];
}

TrendingRestaurantDto _restaurant({
  required int id,
  required int rank,
  required String name,
  String? description,
  bool hasStar = false,
}) {
  return TrendingRestaurantDto(
    id: id,
    name: name,
    description: description,
    address: 'Riyadh',
    latitude: 24.7,
    longitude: 46.7,
    priceLevelId: 2,
    neighborhoodId: 31,
    trendRank: rank,
    hasThurayaStar: hasStar,
    coverPhotoUrl: null,
    categoryIds: const [5],
  );
}
