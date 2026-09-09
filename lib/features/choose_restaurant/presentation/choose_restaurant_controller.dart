import 'package:flutter/foundation.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/choose_restaurant/models/choose_restaurant_dto.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/services/choose_restaurant_service.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';

enum ChooseLookupStatus { idle, loading, ready, error }

enum RecommendationStatus { idle, loading, success, noMatch, error }

typedef RestaurantDetailsLoader =
    Future<RestaurantDetailsDto> Function(int restaurantId);

class ChooseRestaurantController extends ChangeNotifier {
  ChooseRestaurantController({
    RestaurantLookupGateway? lookupGateway,
    ChooseRestaurantGateway? chooseGateway,
    RestaurantDetailsLoader? detailsLoader,
  }) {
    if (lookupGateway == null) {
      final service = RestaurantLookupService();
      _lookupGateway = service;
      _ownedLookupService = service;
    } else {
      _lookupGateway = lookupGateway;
    }

    if (chooseGateway == null) {
      final service = ChooseRestaurantService();
      _chooseGateway = service;
      _ownedChooseService = service;
    } else {
      _chooseGateway = chooseGateway;
    }

    if (detailsLoader == null) {
      final service = RestaurantDetailsService();
      _detailsLoader = service.getDetails;
      _ownedDetailsService = service;
    } else {
      _detailsLoader = detailsLoader;
    }
  }

  late final RestaurantLookupGateway _lookupGateway;
  late final ChooseRestaurantGateway _chooseGateway;
  late final RestaurantDetailsLoader _detailsLoader;
  RestaurantLookupService? _ownedLookupService;
  ChooseRestaurantService? _ownedChooseService;
  RestaurantDetailsService? _ownedDetailsService;
  bool _disposed = false;

  ChooseLookupStatus lookupStatus = ChooseLookupStatus.idle;
  RecommendationStatus recommendationStatus = RecommendationStatus.idle;
  int step = 0;
  List<RestaurantLookupItemDto> priceLevels = const [];
  List<RestaurantLookupItemDto> categories = const [];
  List<NeighborhoodLookupDto> neighborhoods = const [];
  final Set<int> selectedPriceLevelIds = {};
  final Set<int> selectedCategoryIds = {};
  final Set<int> selectedNeighborhoodIds = {};
  String neighborhoodQuery = '';
  ChooseRestaurantRecommendation? recommendation;
  ChooseRestaurantRequest? lastRequest;

  bool get canContinue => switch (step) {
    0 => selectedPriceLevelIds.isNotEmpty,
    1 => selectedCategoryIds.isNotEmpty,
    _ => true,
  };

  List<NeighborhoodLookupDto> get filteredNeighborhoods {
    final query = neighborhoodQuery.trim();
    if (query.isEmpty) return neighborhoods;
    return neighborhoods
        .where((neighborhood) => neighborhood.matches(query))
        .toList(growable: false);
  }

  Future<void> initialize() async {
    if (lookupStatus == ChooseLookupStatus.loading ||
        lookupStatus == ChooseLookupStatus.ready) {
      return;
    }
    lookupStatus = ChooseLookupStatus.loading;
    _notify();
    try {
      final values = await Future.wait<Object>([
        _lookupGateway.getPriceLevels(),
        _lookupGateway.getCategories(),
        _lookupGateway.getNeighborhoods(),
      ]);
      if (_disposed) return;
      priceLevels = values[0] as List<RestaurantLookupItemDto>;
      categories = values[1] as List<RestaurantLookupItemDto>;
      neighborhoods = values[2] as List<NeighborhoodLookupDto>;
      lookupStatus = ChooseLookupStatus.ready;
    } catch (_) {
      if (_disposed) return;
      lookupStatus = ChooseLookupStatus.error;
    }
    _notify();
  }

  void togglePriceLevel(int id) {
    _toggle(selectedPriceLevelIds, id);
  }

  void toggleCategory(int id) {
    _toggle(selectedCategoryIds, id);
  }

  void toggleNeighborhood(int id) {
    _toggle(selectedNeighborhoodIds, id);
  }

  void useAllNeighborhoods() {
    if (selectedNeighborhoodIds.isEmpty) return;
    selectedNeighborhoodIds.clear();
    _notify();
  }

  void updateNeighborhoodQuery(String value) {
    neighborhoodQuery = value;
    _notify();
  }

  void nextStep() {
    if (!canContinue || step >= 2) return;
    step += 1;
    recommendationStatus = RecommendationStatus.idle;
    _notify();
  }

  void previousStep() {
    if (step <= 0) return;
    step -= 1;
    _notify();
  }

  Future<void> requestRecommendation() async {
    if (recommendationStatus == RecommendationStatus.loading) return;
    final request = ChooseRestaurantRequest(
      priceLevelIds: _sorted(selectedPriceLevelIds),
      categoryIds: _sorted(selectedCategoryIds),
      neighborhoodIds: _sorted(selectedNeighborhoodIds),
    );
    lastRequest = request;
    recommendation = null;
    recommendationStatus = RecommendationStatus.loading;
    _notify();

    try {
      final selection = await _chooseGateway.choose(request);
      RestaurantDetailsDto? details;
      try {
        details = await _detailsLoader(selection.id);
      } catch (_) {
        // The choose response is sufficient to render the result. Full details
        // are a best-effort enhancement for photos and Thuraya ratings.
      }
      if (_disposed) return;
      recommendation = ChooseRestaurantRecommendation(
        selection: selection,
        details: details,
      );
      recommendationStatus = RecommendationStatus.success;
    } on ApiException catch (error) {
      if (_disposed) return;
      recommendationStatus = error.statusCode == 404
          ? RecommendationStatus.noMatch
          : RecommendationStatus.error;
    } catch (_) {
      if (_disposed) return;
      recommendationStatus = RecommendationStatus.error;
    }
    _notify();
  }

  void changeSelections() {
    recommendation = null;
    recommendationStatus = RecommendationStatus.idle;
    step = 2;
    _notify();
  }

  void _toggle(Set<int> selection, int id) {
    if (!selection.remove(id)) selection.add(id);
    _notify();
  }

  List<int> _sorted(Set<int> values) => values.toList()..sort();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ownedLookupService?.close();
    _ownedChooseService?.close();
    _ownedDetailsService?.close();
    super.dispose();
  }
}
