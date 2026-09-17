import 'package:flutter/foundation.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/features/home/models/restaurant_map_bounds.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/models/restaurant_search_filters.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/services/restaurant_map_session_cache.dart';

abstract interface class RestaurantSearchGateway {
  Future<List<RestaurantMapMarker>> loadViewport(
    RestaurantSearchFilters filters,
    SupportedMapBounds visibleBounds, {
    required SupportedMapBounds cacheExtent,
    required bool includeListMetadata,
  });
}

class RestaurantMapService implements RestaurantSearchGateway {
  RestaurantMapService({
    ApiClient? apiClient,
    RestaurantMapSessionCache? sessionCache,
  }) : _apiClient = apiClient ?? ApiClient(),
       _ownsApiClient = apiClient == null,
       _sessionCache = sessionCache ?? RestaurantMapSessionCache(),
       _ownsSessionCache = sessionCache == null;

  static const int markerLimit = 500;

  final ApiClient _apiClient;
  final bool _ownsApiClient;
  final RestaurantMapSessionCache _sessionCache;
  final bool _ownsSessionCache;

  @override
  Future<List<RestaurantMapMarker>> loadViewport(
    RestaurantSearchFilters filters,
    SupportedMapBounds visibleBounds, {
    required SupportedMapBounds cacheExtent,
    required bool includeListMetadata,
  }) {
    final needsSearchResponse = includeListMetadata;
    final resultSignature = [
      needsSearchResponse ? 'summary' : 'marker',
      filters.cacheSignature,
    ].join('|');
    return _sessionCache.load(
      visibleBounds: visibleBounds,
      cacheExtent: cacheExtent,
      resultSignature: resultSignature,
      loader: (bounds) => needsSearchResponse
          ? search(filters, bounds)
          : _loadAllMapMarkers(filters, bounds),
    );
  }

  Future<List<RestaurantMapMarker>> getMarkers(SupportedMapBounds bounds) =>
      _loadAllMapMarkers(RestaurantSearchFilters(), bounds);

  Future<List<RestaurantMapMarker>> _loadAllMapMarkers(
    RestaurantSearchFilters filters,
    SupportedMapBounds bounds,
  ) async {
    const maximumPages = 20;
    final markersById = <int, RestaurantMapMarker>{};
    int? afterId;
    for (var pageNumber = 1; pageNumber <= maximumPages; pageNumber++) {
      final stopwatch = Stopwatch()..start();
      final page = filters.isActive
          ? await _getFilteredMapPage(filters, bounds, afterId: afterId)
          : await _getMapPage(bounds, afterId: afterId);
      stopwatch.stop();
      for (final marker in page.items) {
        markersById[marker.id] = marker;
      }
      if (kDebugMode) {
        debugPrint(
          '[restaurant-map] API page received; page=$pageNumber; '
          'resultCount=${page.items.length}; '
          'durationMs=${stopwatch.elapsedMilliseconds}',
        );
      }
      final nextAfterId = page.nextAfterId;
      if (nextAfterId == null) {
        return markersById.values.toList(growable: false);
      }
      if (nextAfterId == afterId) {
        throw const ApiException('The restaurant map page cursor is invalid.');
      }
      afterId = nextAfterId;
    }
    throw const ApiException(
      'The restaurant map area is too dense to load safely.',
    );
  }

  Future<_RestaurantMapPage> _getMapPage(
    SupportedMapBounds bounds, {
    int? afterId,
  }) async {
    final data = await _apiClient.getResultData(
      '/api/restaurants/map',
      queryParameters: RestaurantMapBounds(
        north: bounds.northeastLatitude,
        south: bounds.southwestLatitude,
        east: bounds.northeastLongitude,
        west: bounds.southwestLongitude,
      ).toQueryParameters(limit: markerLimit, afterId: afterId),
    );
    return _RestaurantMapPage.fromData(data);
  }

  Future<_RestaurantMapPage> _getFilteredMapPage(
    RestaurantSearchFilters filters,
    SupportedMapBounds bounds, {
    int? afterId,
  }) async {
    final body = filters.toJson(bounds, limit: markerLimit);
    if (afterId != null) body['afterId'] = afterId;
    try {
      final data = await _apiClient.postResultData(
        '/api/restaurants/map/search',
        body: body,
      );
      return _RestaurantMapPage.fromData(data);
    } on ApiException catch (error) {
      // Keeps the app usable while frontend and backend releases overlap.
      if (error.statusCode != 404 || afterId != null) rethrow;
      final legacyData = await _apiClient.postResultData(
        '/api/restaurants/search',
        body: body,
      );
      return _RestaurantMapPage.fromData(legacyData);
    }
  }

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
    if (_ownsSessionCache) {
      _sessionCache.clear();
    }
    if (_ownsApiClient) {
      _apiClient.close();
    }
  }
}

class _RestaurantMapPage {
  const _RestaurantMapPage({required this.items, required this.nextAfterId});

  final List<RestaurantMapMarker> items;
  final int? nextAfterId;

  factory _RestaurantMapPage.fromData(Object? data) {
    final Object? rawItems;
    final int? nextAfterId;
    if (data is List) {
      rawItems = data;
      nextAfterId = null;
    } else if (data is Map) {
      rawItems = data['items'];
      nextAfterId = (data['nextAfterId'] as num?)?.toInt();
    } else {
      throw const ApiException('The restaurant marker response is invalid.');
    }
    if (rawItems is! List) {
      throw const ApiException('The restaurant marker response is invalid.');
    }
    return _RestaurantMapPage(
      items: rawItems
          .map(
            (marker) => RestaurantMapMarker.fromJson(
              Map<String, dynamic>.from(marker as Map),
            ),
          )
          .toList(growable: false),
      nextAfterId: nextAfterId,
    );
  }
}
