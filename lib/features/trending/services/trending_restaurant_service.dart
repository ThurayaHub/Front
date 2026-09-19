import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/trending/models/trending_restaurant_dto.dart';

abstract interface class TrendingRestaurantGateway {
  Future<List<TrendingRestaurantDto>> getTrending();
}

class TrendingRestaurantService implements TrendingRestaurantGateway {
  TrendingRestaurantService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  @override
  Future<List<TrendingRestaurantDto>> getTrending() async {
    final data = await _apiClient.getResultData('/api/restaurants/trending');
    if (data is! List) {
      throw const ApiException('The trending restaurants response is invalid.');
    }
    return data
        .map(
          (restaurant) => TrendingRestaurantDto.fromJson(
            Map<String, dynamic>.from(restaurant as Map),
          ),
        )
        .toList(growable: false);
  }

  void close() {
    if (_ownsApiClient) _apiClient.close();
  }
}
