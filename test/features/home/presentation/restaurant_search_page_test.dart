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
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

import '../../../fixtures/restaurant_details_fixture.dart';

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
      expect(controller.resultsView, RestaurantResultsView.map);
      expect(_selectedMapRestaurant(tester)?.id, 9);
      expect(
        find.byKey(const ValueKey('restaurant-preview-9')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('restaurant-preview-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('results-list-view')));
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

  testWidgets('filter uses a topmost opaque hit target and opens in one tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = RestaurantSearchController(
      searchGateway: _PageSearchGateway(),
      lookupGateway: const _PageLookupGateway(),
    );
    addTearDown(controller.dispose);
    await controller.loadViewport(_viewport);
    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();

    final filter = find.byKey(const ValueKey('home-filter'));
    expect(filter, findsOneWidget);
    expect(tester.getSize(filter), const Size.square(48));
    final hitTarget = tester.widget<GestureDetector>(filter);
    expect(hitTarget.behavior, HitTestBehavior.opaque);
    expect(hitTarget.onTap, isNotNull);

    await tester.tap(filter);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('restaurant-filter-sheet')),
      findsOneWidget,
    );
  });

  testWidgets('search button submits once and shows region-wide matches', (
    tester,
  ) async {
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

    await tester.enterText(
      find.byKey(const ValueKey('home-search-input')),
      'ثريا',
    );
    final searchButton = find.byKey(const ValueKey('home-search-submit'));
    expect(searchButton, findsOneWidget);
    expect(tester.getSize(searchButton), const Size.square(48));
    final hitTarget = tester.widget<GestureDetector>(searchButton);
    expect(hitTarget.behavior, HitTestBehavior.opaque);
    expect(hitTarget.onTap, isNotNull);

    final requestsBeforeTap = search.requests.length;
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    expect(search.requests, hasLength(requestsBeforeTap + 1));
    expect(search.requests.last.searchText, 'ثريا');
    final requestedBounds = search.requestedBounds.last;
    expect(
      requestedBounds.southwestLatitude,
      SupportedMapRegions.riyadh.bounds.southwestLatitude,
    );
    expect(
      requestedBounds.southwestLongitude,
      SupportedMapRegions.riyadh.bounds.southwestLongitude,
    );
    expect(
      requestedBounds.northeastLatitude,
      SupportedMapRegions.riyadh.bounds.northeastLatitude,
    );
    expect(
      requestedBounds.northeastLongitude,
      SupportedMapRegions.riyadh.bounds.northeastLongitude,
    );

    final map = tester.widget<ThurayaMap>(
      find.ancestor(
        of: find.byKey(const ValueKey('home-map')),
        matching: find.byType(ThurayaMap),
      ),
    );
    expect(map.restaurants, const [_thurayaRestaurant]);
    expect(map.fitRestaurants, isTrue);
  });

  testWidgets('shows and updates restaurant suggestions while typing', (
    tester,
  ) async {
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

    final searchInput = find.byKey(const ValueKey('home-search-input'));
    await tester.enterText(searchInput, 'ث');
    await tester.pump(const Duration(milliseconds: 299));
    expect(search.suggestionRequests, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(search.suggestionRequests.last.searchText, 'ث');
    expect(
      find.byKey(const ValueKey('restaurant-suggestion-dropdown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-suggestion-10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-suggestion-11')),
      findsOneWidget,
    );

    await tester.enterText(searchInput, 'ثري');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(search.suggestionRequests.last.searchText, 'ثري');
    expect(
      find.byKey(const ValueKey('restaurant-suggestion-10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('restaurant-suggestion-11')),
      findsNothing,
    );
    expect(controller.filters.searchText, isEmpty);

    await tester.tap(find.byKey(const ValueKey('restaurant-suggestion-10')));
    await tester.pumpAndSettle();

    expect(_selectedMapRestaurant(tester)?.id, 10);
    expect(find.byKey(const ValueKey('restaurant-preview-10')), findsOneWidget);
    expect(controller.filters.searchText, isEmpty);
    expect(
      tester
          .widget<TextField>(
            find.byKey(
              const ValueKey('home-search-input'),
              skipOffstage: false,
            ),
          )
          .controller!
          .text,
      'ثري',
    );

    await tester.tap(find.byKey(const ValueKey('restaurant-preview-close')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('restaurant-suggestion-dropdown')),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(searchInput).controller!.text, 'ثري');
  });

  testWidgets(
    'scrolling and hiding the keyboard keep search results and position',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = RestaurantSearchController(
        searchGateway: _PageSearchGateway(),
        lookupGateway: const _PageLookupGateway(),
      );
      addTearDown(controller.dispose);
      await controller.loadViewport(_viewport);
      await tester.pumpWidget(_TestApp(controller: controller));
      await tester.pumpAndSettle();

      final input = find.byKey(const ValueKey('home-search-input'));
      await tester.enterText(input, 'many');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final list = find.byKey(const ValueKey('restaurant-suggestion-list'));
      expect(list, findsOneWidget);
      await tester.drag(list, const Offset(0, -180));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)),
      );
      final offsetBeforeDetails = scrollable.position.pixels;

      expect(offsetBeforeDetails, greaterThan(0));
      expect(find.byKey(const ValueKey('home-search-close')), findsOneWidget);
      expect(tester.widget<TextField>(input).controller!.text, 'many');
      expect(
        find.byKey(const ValueKey('restaurant-suggestion-dropdown')),
        findsOneWidget,
      );

      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('restaurant-suggestion-dropdown')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('restaurant-suggestion-105')));
      await tester.pumpAndSettle();
      expect(_selectedMapRestaurant(tester)?.id, 105);
      expect(
        find.byKey(const ValueKey('restaurant-preview-105')),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final restoredScrollable = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)),
      );
      expect(restoredScrollable.position.pixels, offsetBeforeDetails);
      expect(tester.widget<TextField>(input).controller!.text, 'many');
      expect(
        find.byKey(const ValueKey('restaurant-suggestion-dropdown')),
        findsOneWidget,
      );
    },
  );

  testWidgets('explicit close and back are the only search exit paths', (
    tester,
  ) async {
    final controller = RestaurantSearchController(
      searchGateway: _PageSearchGateway(),
      lookupGateway: const _PageLookupGateway(),
    );
    addTearDown(controller.dispose);
    await controller.loadViewport(_viewport);
    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();

    final input = find.byKey(const ValueKey('home-search-input'));
    await tester.enterText(input, 'ثري');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('restaurant-suggestion-10')));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('restaurant-suggestion-dropdown')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('restaurant-suggestion-dropdown')),
      findsNothing,
    );
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);

    await tester.tap(input);
    await tester.enterText(input, 'ثري');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-search-close')));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(input).controller!.text, isEmpty);
    expect(
      find.byKey(const ValueKey('restaurant-suggestion-dropdown')),
      findsNothing,
    );
  });
}

class _TestApp extends StatelessWidget {
  _TestApp({required this.controller});

  final RestaurantSearchController controller;
  final RestaurantDetailsService restaurantDetailsService =
      _SearchPreviewDetailsService();

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
      home: HomePage(
        controller: controller,
        restaurantDetailsService: restaurantDetailsService,
      ),
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

RestaurantMapMarker? _selectedMapRestaurant(WidgetTester tester) {
  return tester
      .widget<ThurayaMap>(
        find.ancestor(
          of: find.byKey(const ValueKey('home-map')),
          matching: find.byType(ThurayaMap),
        ),
      )
      .selectedRestaurant;
}

class _SearchPreviewDetailsService extends RestaurantDetailsService {
  @override
  Future<RestaurantDetailsDto> getDetails(int restaurantId) async {
    return RestaurantDetailsDto.fromJson({
      ...restaurantDetailsData,
      'id': restaurantId,
    });
  }
}

class _PageSearchGateway implements RestaurantSearchGateway {
  final List<RestaurantSearchFilters> requests = [];
  final List<SupportedMapBounds> requestedBounds = [];
  final List<RestaurantSearchFilters> suggestionRequests = [];

  @override
  Future<List<RestaurantMapMarker>> loadViewport(
    RestaurantSearchFilters filters,
    SupportedMapBounds bounds, {
    required SupportedMapBounds cacheExtent,
    required bool includeListMetadata,
  }) async {
    requests.add(filters);
    requestedBounds.add(bounds);
    return switch (filters.searchText) {
      '__empty__' => const [],
      'ثريا' || 'ثريا الرياض' => const [_thurayaRestaurant],
      _ => const [_restaurant],
    };
  }

  @override
  Future<List<RestaurantMapMarker>> loadSuggestions(
    RestaurantSearchFilters filters,
    SupportedMapBounds bounds, {
    int limit = 6,
  }) async {
    suggestionRequests.add(filters);
    return switch (filters.searchText) {
      'many' => List.generate(
        12,
        (index) => RestaurantMapMarker(
          id: 100 + index,
          name: 'Restaurant $index',
          nameArabic: 'مطعم $index',
          latitude: 24.70 + index * 0.001,
          longitude: 46.60 + index * 0.001,
          hasThurayaStar: false,
        ),
      ),
      'ثري' => const [_thurayaRestaurant],
      _ => const [_thurayaRestaurant, _secondSuggestion],
    };
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

const _thurayaRestaurant = RestaurantMapMarker(
  id: 10,
  name: 'Thuraya Riyadh',
  nameArabic: 'ثريا الرياض',
  latitude: 24.72,
  longitude: 46.68,
  hasThurayaStar: true,
  neighborhoodNameAr: 'العليا',
  neighborhoodNameEn: 'Al Olaya',
);

const _secondSuggestion = RestaurantMapMarker(
  id: 11,
  name: 'Thawb Cafe',
  nameArabic: 'ثوب كافيه',
  latitude: 24.73,
  longitude: 46.69,
  placeType: RestaurantMapPlaceType.cafe,
  hasThurayaStar: false,
  neighborhoodNameAr: 'الملقا',
  neighborhoodNameEn: 'Al Malqa',
);
