import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';
import 'package:thuraya/features/trending/models/trending_restaurant_dto.dart';
import 'package:thuraya/features/trending/presentation/trending_controller.dart';
import 'package:thuraya/features/trending/services/trending_restaurant_service.dart';

void main() {
  test('preserves backend order and caches lookups across refreshes', () async {
    final trending = _TrendingGateway([
      _restaurant(id: 70, rank: 7),
      _restaurant(id: 20, rank: 2),
    ]);
    final lookups = _LookupGateway();
    final controller = TrendingController(
      trendingGateway: trending,
      lookupGateway: lookups,
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.status, TrendingLoadStatus.ready);
    expect(controller.restaurants.map((item) => item.id), [70, 20]);
    expect(controller.restaurants.map((item) => item.trendRank), [7, 2]);
    expect(controller.priceLevelById(2)?.name, 'Medium');
    expect(controller.categoryById(5)?.name, 'Saudi');
    expect(controller.neighborhoodById(31)?.nameAr, 'العليا');
    expect(trending.calls, 1);
    expect(lookups.priceCalls, 1);
    expect(lookups.categoryCalls, 1);
    expect(lookups.neighborhoodCalls, 1);

    await controller.load(refresh: true);
    expect(trending.calls, 2);
    expect(lookups.priceCalls, 1);
    expect(lookups.categoryCalls, 1);
    expect(lookups.neighborhoodCalls, 1);
  });

  test('exposes an error state when the trending request fails', () async {
    final controller = TrendingController(
      trendingGateway: _FailingTrendingGateway(),
      lookupGateway: _LookupGateway(),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.status, TrendingLoadStatus.error);
    expect(controller.restaurants, isEmpty);
  });
}

class _TrendingGateway implements TrendingRestaurantGateway {
  _TrendingGateway(this.restaurants);

  final List<TrendingRestaurantDto> restaurants;
  int calls = 0;

  @override
  Future<List<TrendingRestaurantDto>> getTrending() async {
    calls++;
    return restaurants;
  }
}

class _FailingTrendingGateway implements TrendingRestaurantGateway {
  @override
  Future<List<TrendingRestaurantDto>> getTrending() =>
      Future.error(StateError('offline'));
}

class _LookupGateway implements RestaurantLookupGateway {
  int priceCalls = 0;
  int categoryCalls = 0;
  int neighborhoodCalls = 0;

  @override
  Future<List<RestaurantLookupItemDto>> getPriceLevels() async {
    priceCalls++;
    return const [
      RestaurantLookupItemDto(id: 2, name: 'Medium', description: null),
    ];
  }

  @override
  Future<List<RestaurantLookupItemDto>> getCategories() async {
    categoryCalls++;
    return const [
      RestaurantLookupItemDto(id: 5, name: 'Saudi', description: null),
    ];
  }

  @override
  Future<List<NeighborhoodLookupDto>> getNeighborhoods() async {
    neighborhoodCalls++;
    return const [
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
}

TrendingRestaurantDto _restaurant({required int id, required int rank}) {
  return TrendingRestaurantDto(
    id: id,
    name: 'Restaurant $id',
    description: null,
    address: 'Riyadh',
    latitude: 24.7,
    longitude: 46.7,
    priceLevelId: 2,
    neighborhoodId: 31,
    trendRank: rank,
    hasThurayaStar: false,
    coverPhotoUrl: null,
    categoryIds: const [5],
  );
}
