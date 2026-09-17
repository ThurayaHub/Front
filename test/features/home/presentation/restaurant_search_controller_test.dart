import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/presentation/restaurant_search_controller.dart';
import 'package:thuraya/features/home/services/restaurant_map_service.dart';

void main() {
  test(
    'keeps applied filters, results, and view mode in one state object',
    () async {
      final search = _SearchGateway(results: const [_restaurant]);
      final controller = RestaurantSearchController(
        searchGateway: search,
        lookupGateway: const _LookupGateway(),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.loadViewport(_viewport);
      final filters = RestaurantSearchFilters(
        searchText: 'burger',
        priceLevelIds: {2, 3},
        categoryIds: {5},
        minimumUserRating: 4,
        hasThurayaRating: true,
      );
      await controller.applyFilters(filters);
      controller.setResultsView(RestaurantResultsView.list);
      await Future<void>.delayed(Duration.zero);

      expect(controller.filters, filters);
      expect(controller.results, const [_restaurant]);
      expect(controller.resultsView, RestaurantResultsView.list);
      expect(controller.filters.activeFilterCount, 5);
      expect(search.requests.last, filters);
      expect(search.includeListMetadata.last, isTrue);
      expect(controller.priceLevelById(2)?.name, 'Medium');
      expect(controller.categoryById(5)?.name, 'American');
    },
  );

  test(
    'does not send a duplicate request for the same in-flight state',
    () async {
      final completer = Completer<List<RestaurantMapMarker>>();
      final search = _SearchGateway(completer: completer);
      final controller = RestaurantSearchController(
        searchGateway: search,
        lookupGateway: const _LookupGateway(),
      );
      addTearDown(controller.dispose);

      final first = controller.loadViewport(_viewport);
      await Future<void>.delayed(Duration.zero);
      await controller.loadViewport(_viewport);
      expect(search.requests, hasLength(1));

      completer.complete(const [_restaurant]);
      await first;
      expect(controller.results, const [_restaurant]);
    },
  );
}

class _SearchGateway implements RestaurantSearchGateway {
  _SearchGateway({this.results = const [], this.completer});

  final List<RestaurantMapMarker> results;
  final Completer<List<RestaurantMapMarker>>? completer;
  final List<RestaurantSearchFilters> requests = [];
  final List<bool> includeListMetadata = [];

  @override
  Future<List<RestaurantMapMarker>> loadViewport(
    RestaurantSearchFilters filters,
    SupportedMapBounds bounds, {
    required SupportedMapBounds cacheExtent,
    required bool includeListMetadata,
  }) {
    requests.add(filters);
    this.includeListMetadata.add(includeListMetadata);
    return completer?.future ?? Future.value(results);
  }
}

const _viewport = SupportedMapBounds(
  southwestLatitude: 24.6,
  southwestLongitude: 46.5,
  northeastLatitude: 24.8,
  northeastLongitude: 46.8,
);

class _LookupGateway implements RestaurantLookupGateway {
  const _LookupGateway();

  @override
  Future<List<RestaurantLookupItemDto>> getCategories() async => const [
    RestaurantLookupItemDto(id: 5, name: 'American', description: null),
  ];

  @override
  Future<List<NeighborhoodLookupDto>> getNeighborhoods() async => const [];

  @override
  Future<List<RestaurantLookupItemDto>> getPriceLevels() async => const [
    RestaurantLookupItemDto(id: 2, name: 'Medium', description: null),
    RestaurantLookupItemDto(id: 3, name: 'Expensive', description: null),
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
  thurayaRatingAverage: 9,
  thurayaReviewCount: 1,
  userRatingAverage: 4.5,
  reviewCount: 12,
  mainPhotoUrl: null,
  primaryCategoryId: 5,
  primaryCategoryName: 'American',
  neighborhoodId: 4,
  neighborhoodNameAr: 'العليا',
  neighborhoodNameEn: 'Al Olaya',
  address: 'العليا، الرياض',
);
