import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/home/models/restaurant_map_bounds.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';

abstract interface class RestaurantSearchGateway {
  Future<List<RestaurantMapMarker>> search(
    RestaurantSearchFilters filters,
    SupportedMapBounds bounds,
  );
}

class RestaurantMapService implements RestaurantSearchGateway {
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

  @override
  Future<List<RestaurantMapMarker>> search(
    RestaurantSearchFilters filters,
    SupportedMapBounds bounds,
  ) async {
    final data = await _apiClient.postResultData(
      '/api/restaurants/search',
      body: filters.toJson(bounds, limit: 500),
    );
    if (data is! List) {
      throw const ApiException('The restaurant search response is invalid.');
    }

    return data
        .map(
          (restaurant) => RestaurantMapMarker.fromJson(
            Map<String, dynamic>.from(restaurant as Map),
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
