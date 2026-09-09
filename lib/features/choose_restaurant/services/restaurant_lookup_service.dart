import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';

abstract interface class RestaurantLookupGateway {
  Future<List<RestaurantLookupItemDto>> getPriceLevels();

  Future<List<RestaurantLookupItemDto>> getCategories();

  Future<List<NeighborhoodLookupDto>> getNeighborhoods();
}

class RestaurantLookupService implements RestaurantLookupGateway {
  RestaurantLookupService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  @override
  Future<List<RestaurantLookupItemDto>> getPriceLevels() async {
    final data = await _apiClient.getResultData('/api/lookups/price-levels');
    return _parseList(data, RestaurantLookupItemDto.fromJson);
  }

  @override
  Future<List<RestaurantLookupItemDto>> getCategories() async {
    final data = await _apiClient.getResultData(
      '/api/lookups/restaurant-categories',
    );
    return _parseList(data, RestaurantLookupItemDto.fromJson);
  }

  @override
  Future<List<NeighborhoodLookupDto>> getNeighborhoods() async {
    final data = await _apiClient.getResultData('/api/lookups/neighborhoods');
    return _parseList(data, NeighborhoodLookupDto.fromJson);
  }

  void close() {
    if (_ownsApiClient) _apiClient.close();
  }
}

List<T> _parseList<T>(Object? data, T Function(Map<String, dynamic>) parser) {
  if (data is! List) {
    throw const ApiException('The lookup response is invalid.');
  }
  return data
      .map((item) => parser(Map<String, dynamic>.from(item as Map)))
      .toList(growable: false);
}
