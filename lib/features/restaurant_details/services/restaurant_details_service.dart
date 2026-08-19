import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';

class RestaurantDetailsService {
  RestaurantDetailsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<RestaurantDetailsDto> getDetails(int restaurantId) async {
    final data = await _apiClient.getResultData(
      '/api/restaurants/$restaurantId',
    );
    if (data is! Map) {
      throw const ApiException('The restaurant details response is invalid.');
    }
    return RestaurantDetailsDto.fromJson(Map<String, dynamic>.from(data));
  }

  void close() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }
}
