import 'package:flutter/foundation.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';
import 'package:thuraya/features/trending/models/trending_restaurant_dto.dart';
import 'package:thuraya/features/trending/services/trending_restaurant_service.dart';

enum TrendingLoadStatus { idle, loading, ready, error }

class TrendingController extends ChangeNotifier {
  TrendingController({
    TrendingRestaurantGateway? trendingGateway,
    RestaurantLookupGateway? lookupGateway,
  }) : _trendingGateway = trendingGateway ?? TrendingRestaurantService(),
       _lookupGateway = lookupGateway ?? RestaurantLookupService(),
       _ownsTrendingGateway = trendingGateway == null,
       _ownsLookupGateway = lookupGateway == null;

  final TrendingRestaurantGateway _trendingGateway;
  final RestaurantLookupGateway _lookupGateway;
  final bool _ownsTrendingGateway;
  final bool _ownsLookupGateway;

  bool _disposed = false;
  bool _lookupsLoaded = false;
  bool isRefreshing = false;
  TrendingLoadStatus status = TrendingLoadStatus.idle;
  List<TrendingRestaurantDto> restaurants = const [];
  List<RestaurantLookupItemDto> priceLevels = const [];
  List<RestaurantLookupItemDto> categories = const [];
  List<NeighborhoodLookupDto> neighborhoods = const [];

  Future<void> load({bool refresh = false}) async {
    if (status == TrendingLoadStatus.loading ||
        isRefreshing ||
        (!refresh && status == TrendingLoadStatus.ready)) {
      return;
    }

    final keepCurrentContent = refresh && status == TrendingLoadStatus.ready;
    if (keepCurrentContent) {
      isRefreshing = true;
    } else {
      status = TrendingLoadStatus.loading;
    }
    _notify();
    try {
      if (_lookupsLoaded) {
        final nextRestaurants = await _trendingGateway.getTrending();
        if (_disposed) return;
        restaurants = nextRestaurants;
        status = TrendingLoadStatus.ready;
      } else {
        final results = await Future.wait<Object>([
          _trendingGateway.getTrending(),
          _lookupGateway.getPriceLevels(),
          _lookupGateway.getCategories(),
          _lookupGateway.getNeighborhoods(),
        ]);
        if (_disposed) return;

        // The backend owns the order. Never regenerate ranks or sort by index.
        restaurants = results[0] as List<TrendingRestaurantDto>;
        priceLevels = results[1] as List<RestaurantLookupItemDto>;
        categories = results[2] as List<RestaurantLookupItemDto>;
        neighborhoods = results[3] as List<NeighborhoodLookupDto>;
        _lookupsLoaded = true;
        status = TrendingLoadStatus.ready;
      }
    } catch (_) {
      if (_disposed) return;
      status = keepCurrentContent
          ? TrendingLoadStatus.ready
          : TrendingLoadStatus.error;
    } finally {
      isRefreshing = false;
    }
    _notify();
  }

  RestaurantLookupItemDto? priceLevelById(int id) => _itemById(priceLevels, id);

  RestaurantLookupItemDto? categoryById(int id) => _itemById(categories, id);

  NeighborhoodLookupDto? neighborhoodById(int? id) {
    if (id == null) return null;
    for (final neighborhood in neighborhoods) {
      if (neighborhood.id == id) return neighborhood;
    }
    return null;
  }

  RestaurantLookupItemDto? _itemById(
    List<RestaurantLookupItemDto> items,
    int id,
  ) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsTrendingGateway && _trendingGateway is TrendingRestaurantService) {
      _trendingGateway.close();
    }
    if (_ownsLookupGateway && _lookupGateway is RestaurantLookupService) {
      _lookupGateway.close();
    }
    super.dispose();
  }
}
