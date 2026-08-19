import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/home/models/restaurant_map_bounds.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';

class RestaurantMapService {
  RestaurantMapService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(),
      _ownsApiClient = apiClient == null;

  static const int markerLimit = 200;

  final ApiClient _apiClient;
  final bool _ownsApiClient;

  Future<List<RestaurantMapMarker>> getMarkers(
    RestaurantMapBounds bounds,
  ) async {
    final data = await _apiClient.getResultData(
      '/api/restaurants/map',
      queryParameters: bounds.toQueryParameters(limit: markerLimit),
    );
    if (data is! List) {
      throw const ApiException('The restaurant marker response is invalid.');
    }

    return data
        .map(
          (marker) => RestaurantMapMarker.fromJson(
            Map<String, dynamic>.from(marker as Map),
          ),
        )
        .toList(growable: false);
  }

  void close() {
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }
}
