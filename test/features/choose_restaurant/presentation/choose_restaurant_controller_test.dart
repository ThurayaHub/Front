import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/choose_restaurant/models/choose_restaurant_dto.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_controller.dart';
import 'package:thuraya/features/choose_restaurant/services/choose_restaurant_service.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';

void main() {
  test('loads lookups and preserves multi-selections between steps', () async {
    final controller = _controller();
    addTearDown(controller.dispose);

    await controller.initialize();
    controller.togglePriceLevel(4);
    controller.togglePriceLevel(2);
    controller.nextStep();
    controller.toggleCategory(8);
    controller.toggleCategory(2);
    controller.nextStep();
    controller.toggleNeighborhood(15);
    controller.previousStep();
    controller.nextStep();

    expect(controller.lookupStatus, ChooseLookupStatus.ready);
    expect(controller.selectedPriceLevelIds, {2, 4});
    expect(controller.selectedCategoryIds, {2, 8});
    expect(controller.selectedNeighborhoodIds, {15});
    expect(controller.step, 2);
  });

  test('searches Arabic and English neighborhood names', () async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await controller.initialize();

    controller.updateNeighborhoodQuery('علي');
    expect(controller.filteredNeighborhoods.single.id, 15);
    controller.updateNeighborhoodQuery('malqa');
    expect(controller.filteredNeighborhoods.single.id, 16);
  });

  test('sends sorted selected IDs and choose again keeps criteria', () async {
    final gateway = _ChooseGateway();
    final controller = _controller(chooseGateway: gateway);
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.togglePriceLevel(4);
    controller.togglePriceLevel(2);
    controller.toggleCategory(8);
    controller.toggleCategory(2);
    controller.toggleNeighborhood(16);

    await controller.requestRecommendation();
    await controller.requestRecommendation();

    expect(gateway.requests, hasLength(2));
    for (final request in gateway.requests) {
      expect(request.toJson(), {
        'priceLevelIds': [2, 4],
        'categoryIds': [2, 8],
        'neighborhoodIds': [16],
      });
    }
    expect(controller.recommendationStatus, RecommendationStatus.success);
  });

  test('turns a backend 404 into the friendly no-match state', () async {
    final controller = _controller(chooseGateway: _NoMatchGateway());
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.requestRecommendation();

    expect(controller.recommendationStatus, RecommendationStatus.noMatch);
    expect(controller.recommendation, isNull);
  });
}

ChooseRestaurantController _controller({
  ChooseRestaurantGateway? chooseGateway,
}) {
  return ChooseRestaurantController(
    lookupGateway: _LookupGateway(),
    chooseGateway: chooseGateway ?? _ChooseGateway(),
    detailsLoader: (_) => Future.error(const ApiException('No details')),
  );
}

class _LookupGateway implements RestaurantLookupGateway {
  @override
  Future<List<RestaurantLookupItemDto>> getPriceLevels() async => const [
    RestaurantLookupItemDto(id: 2, name: 'Medium', description: null),
    RestaurantLookupItemDto(id: 4, name: 'Very Expensive', description: null),
  ];

  @override
  Future<List<RestaurantLookupItemDto>> getCategories() async => const [
    RestaurantLookupItemDto(id: 2, name: 'Asian', description: null),
    RestaurantLookupItemDto(id: 8, name: 'Japanese', description: null),
  ];

  @override
  Future<List<NeighborhoodLookupDto>> getNeighborhoods() async => const [
    NeighborhoodLookupDto(
      id: 15,
      nameAr: 'العليا',
      nameEn: 'Al Olaya',
      cityAr: 'الرياض',
      cityEn: 'Riyadh',
      countryCode: 'SA',
    ),
    NeighborhoodLookupDto(
      id: 16,
      nameAr: 'الملقا',
      nameEn: 'Al Malqa',
      cityAr: 'الرياض',
      cityEn: 'Riyadh',
      countryCode: 'SA',
    ),
  ];
}

class _ChooseGateway implements ChooseRestaurantGateway {
  final requests = <ChooseRestaurantRequest>[];

  @override
  Future<ChooseRestaurantResponseDto> choose(
    ChooseRestaurantRequest request,
  ) async {
    requests.add(request);
    return _selection;
  }
}

class _NoMatchGateway implements ChooseRestaurantGateway {
  @override
  Future<ChooseRestaurantResponseDto> choose(ChooseRestaurantRequest request) {
    throw const ApiException('No match', statusCode: 404);
  }
}

const _selection = ChooseRestaurantResponseDto(
  id: 42,
  name: 'Riyadh Table',
  nameArabic: 'مائدة الرياض',
  description: 'A modern restaurant.',
  descriptionArabic: 'مطعم عصري.',
  address: 'Riyadh',
  latitude: 24.7,
  longitude: 46.6,
  googleMapsUrl: 'https://maps.example/42',
  priceLevelId: 2,
  priceLevelName: 'Medium',
  neighborhoodId: 15,
  neighborhoodNameAr: 'العليا',
  neighborhoodNameEn: 'Al Olaya',
  userRatingAverage: 4.5,
  reviewCount: 8,
  mainPhotoUrl: null,
  hasThurayaStar: true,
  categories: [],
);
