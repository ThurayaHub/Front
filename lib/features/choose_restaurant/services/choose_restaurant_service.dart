import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/choose_restaurant/models/choose_restaurant_dto.dart';

abstract interface class ChooseRestaurantGateway {
  Future<ChooseRestaurantResponseDto> choose(ChooseRestaurantRequest request);
}

class ChooseRestaurantService implements ChooseRestaurantGateway {
  ChooseRestaurantService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  @override
  Future<ChooseRestaurantResponseDto> choose(
    ChooseRestaurantRequest request,
  ) async {
    final data = await _apiClient.postResultData(
      '/api/restaurants/choose',
      body: request.toJson(),
    );
    if (data is! Map) {
      throw const ApiException('The recommendation response is invalid.');
    }
    return ChooseRestaurantResponseDto.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  void close() {
    if (_ownsApiClient) _apiClient.close();
  }
}
