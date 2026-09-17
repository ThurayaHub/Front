import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_theme.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/presentation/home_page.dart';
import 'package:thuraya/features/home/presentation/restaurant_search_controller.dart';
import 'package:thuraya/features/home/presentation/widgets/thuraya_map.dart';
import 'package:thuraya/features/home/services/restaurant_map_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mapChannel = MethodChannel('plugins.flutter.io/maplibre_gl_0');
  late MapLibrePlatform Function() previousMapPlatformFactory;

  setUp(() async {
    previousMapPlatformFactory = MapLibrePlatform.createInstance;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mapChannel, (_) async => null);
    final platform = MapLibreMethodChannel();
    await platform.initPlatform(0);
    MapLibrePlatform.createInstance = () => platform;
  });

  tearDown(() {
    MapLibrePlatform.createInstance = previousMapPlatformFactory;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mapChannel, null);
  });

  testWidgets(
    'applies optional filters and keeps Map/List results synchronized',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final search = _PageSearchGateway();
      final controller = RestaurantSearchController(
        searchGateway: search,
        lookupGateway: const _PageLookupGateway(),
      );
      addTearDown(controller.dispose);
      await controller.loadViewport(_viewport);

      await tester.pumpWidget(_TestApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('1 مطعم'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home-filter')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('restaurant-filter-sheet')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('filter-search-input')),
        'برجر',
      );
      await tester.tap(find.byKey(const ValueKey('filter-price-2')));
      await tester.tap(find.byKey(const ValueKey('filter-price-3')));
      await tester.tap(find.byKey(const ValueKey('filter-category-6')));
      await tester.tap(find.byKey(const ValueKey('filter-category-8')));
      await tester.tap(find.byKey(const ValueKey('filter-rating-4')));
      await tester.tap(find.byKey(const ValueKey('filter-thuraya-rating')));
      await tester.tap(find.byKey(const ValueKey('filter-show-results')));
      await tester.pumpAndSettle();

      final filters = search.requests.last;
      expect(filters.searchText, 'برجر');
      expect(filters.priceLevelIds, {2, 3});
      expect(filters.categoryIds, {6, 8});
      expect(filters.minimumUserRating, 4);
      expect(filters.hasThurayaRating, isTrue);
      expect(find.text('6'), findsOneWidget);

      final map = tester.widget<ThurayaMap>(
        find.ancestor(
          of: find.byKey(const ValueKey('home-map')),
          matching: find.byType(ThurayaMap),
        ),
      );
      expect(map.restaurants, const [_restaurant]);

      await tester.tap(find.byKey(const ValueKey('results-list-view')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('restaurant-result-9')), findsOneWidget);
      expect(find.text('بيت البرجر'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('restaurant-result-9')));
      await tester.pumpAndSettle();
      expect(find.text('details-9'), findsOneWidget);
      Navigator.of(tester.element(find.text('details-9'))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('restaurant-result-9')), findsOneWidget);
      expect(controller.resultsView, RestaurantResultsView.list);

      await tester.tap(find.byKey(const ValueKey('results-map-view')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-map')), findsOneWidget);
      expect(controller.filters, filters);

      await tester.tap(find.byKey(const ValueKey('home-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-clear-all')));
      await tester.tap(find.byKey(const ValueKey('filter-show-results')));
      await tester.pumpAndSettle();
      expect(controller.filters.isActive, isFalse);
      expect(find.byKey(const ValueKey('home-filter-badge')), findsNothing);
    },
  );

  testWidgets('supports English text and explains empty results in Arabic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final search = _PageSearchGateway();
    final controller = RestaurantSearchController(
      searchGateway: search,
      lookupGateway: const _PageLookupGateway(),
    );
    addTearDown(controller.dispose);
    await controller.loadViewport(_viewport);
    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('home-search-input')),
      'burger',
    );
    await tester.tap(find.byKey(const ValueKey('home-search-submit')));
    await tester.pumpAndSettle();
    expect(search.requests.last.searchText, 'burger');

    await tester.enterText(
      find.byKey(const ValueKey('home-search-input')),
      '__empty__',
    );
    await tester.tap(find.byKey(const ValueKey('home-search-submit')));
    await tester.pumpAndSettle();
    expect(find.text('ما لقينا مطاعم تطابق بحثك'), findsOneWidget);
    expect(find.text('جرّب تغيير البحث أو إزالة بعض الفلاتر'), findsOneWidget);
    expect(find.text('مسح الفلاتر'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller});

  final RestaurantSearchController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(controller: controller),
      onGenerateRoute: (settings) {
        if (settings.name == AppRouteNames.restaurantDetails) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                Scaffold(body: Text('details-${settings.arguments}')),
          );
        }
        return null;
      },
    );
  }
}

class _PageSearchGateway implements RestaurantSearchGateway {
  final List<RestaurantSearchFilters> requests = [];

  @override
  Future<List<RestaurantMapMarker>> loadViewport(
    RestaurantSearchFilters filters,
    SupportedMapBounds bounds, {
    required SupportedMapBounds cacheExtent,
    required bool includeListMetadata,
  }) async {
    requests.add(filters);
    return filters.searchText == '__empty__' ? const [] : const [_restaurant];
  }
}

const _viewport = SupportedMapBounds(
  southwestLatitude: 24.6,
  southwestLongitude: 46.5,
  northeastLatitude: 24.8,
  northeastLongitude: 46.8,
);

class _PageLookupGateway implements RestaurantLookupGateway {
  const _PageLookupGateway();

  @override
  Future<List<RestaurantLookupItemDto>> getCategories() async => const [
    RestaurantLookupItemDto(id: 6, name: 'Italian', description: null),
    RestaurantLookupItemDto(id: 8, name: 'Japanese', description: null),
  ];

  @override
  Future<List<NeighborhoodLookupDto>> getNeighborhoods() async => const [];

  @override
  Future<List<RestaurantLookupItemDto>> getPriceLevels() async => const [
    RestaurantLookupItemDto(id: 1, name: 'Cheap', description: null),
    RestaurantLookupItemDto(id: 2, name: 'Medium', description: null),
    RestaurantLookupItemDto(id: 3, name: 'Expensive', description: null),
    RestaurantLookupItemDto(id: 4, name: 'Very Expensive', description: null),
  ];
}

const _restaurant = RestaurantMapMarker(
  id: 9,
  name: 'Burger House',
  nameArabic: 'بيت البرجر',
  latitude: 24.71,
  longitude: 46.67,
  priceLevelId: 2,
  priceLevelName: 'Medium',
  hasThurayaStar: false,
  thurayaRatingAverage: 8,
  thurayaReviewCount: 1,
  userRatingAverage: 4.5,
  reviewCount: 12,
  mainPhotoUrl: null,
  primaryCategoryId: 6,
  primaryCategoryName: 'Italian',
  neighborhoodId: 4,
  neighborhoodNameAr: 'العليا',
  neighborhoodNameEn: 'Al Olaya',
  address: 'العليا، الرياض',
);
