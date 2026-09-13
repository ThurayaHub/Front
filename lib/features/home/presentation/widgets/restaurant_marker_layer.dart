import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';

/// Owns the native MapLibre source and style layers used for restaurant POIs.
///
/// Restaurants stay in one clustered GeoJSON source so grouping, collision
/// detection, and drawing happen on the map renderer instead of in Flutter.
/// The selected restaurant uses a tiny second source so highlighting it never
/// forces the full clustered source to be rebuilt.
abstract final class RestaurantMarkerLayer {
  static const String sourceId = 'thuraya-restaurants-source';
  static const String _selectedSourceId = 'thuraya-selected-restaurant-source';

  static const String _clusterShadowLayerId =
      'thuraya-restaurant-cluster-shadow-layer';
  static const String clusterLayerId = 'thuraya-restaurant-clusters-layer';
  static const String _pointHitLayerId = 'thuraya-restaurant-point-hit-layer';
  static const String _pointShadowLayerId =
      'thuraya-restaurant-point-shadow-layer';
  static const String _pointLayerId = 'thuraya-restaurant-points-layer';
  static const String _restaurantGlyphLayerId =
      'thuraya-restaurant-point-glyph-layer';
  static const String _cafeGlyphLayerId = 'thuraya-cafe-point-glyph-layer';
  static const String _cafeGlyphCenterLayerId =
      'thuraya-cafe-point-glyph-center-layer';
  static const String _selectedHaloLayerId =
      'thuraya-selected-restaurant-halo-layer';
  static const String _selectedPointLayerId =
      'thuraya-selected-restaurant-point-layer';
  static const String _selectedRestaurantGlyphLayerId =
      'thuraya-selected-restaurant-glyph-layer';
  static const String _selectedCafeGlyphLayerId =
      'thuraya-selected-cafe-glyph-layer';
  static const String _selectedCafeGlyphCenterLayerId =
      'thuraya-selected-cafe-glyph-center-layer';
  static const double clusterMaxZoom = 14;
  static const double individualFocusZoom = 15.5;

  static const List<Object> _clusterFilter = ['has', 'point_count'];
  static const List<Object> _pointFilter = [
    '!',
    ['has', 'point_count'],
  ];

  static Future<void> install(MapLibreMapController controller) async {
    await controller.addSource(
      sourceId,
      GeojsonSourceProperties(
        data: featureCollection(const [], 'en'),
        cluster: true,
        clusterRadius: 54,
        clusterMaxZoom: clusterMaxZoom,
        maxzoom: 18,
      ),
    );
    await controller.addGeoJsonSource(
      _selectedSourceId,
      featureCollection(const [], 'en'),
    );

    await _addClusterLayers(controller);
    await _addPointLayers(controller);
    await _addSelectedLayers(controller);
  }

  static Future<void> _addClusterLayers(
    MapLibreMapController controller,
  ) async {
    await controller.addCircleLayer(
      sourceId,
      _clusterShadowLayerId,
      CircleLayerProperties(
        circleRadius: _clusterShadowRadius,
        circleColor: 'rgba(0, 6, 102, 0.22)',
        circleBlur: 0.65,
      ),
      filter: _clusterFilter,
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      sourceId,
      clusterLayerId,
      CircleLayerProperties(
        circleRadius: _clusterRadius,
        circleColor: _clusterColor,
        circleStrokeWidth: 3,
        circleStrokeColor: _mapColor(AppColors.surface),
      ),
      filter: _clusterFilter,
      enableInteraction: true,
    );
  }

  static Future<void> _addPointLayers(MapLibreMapController controller) async {
    // The nearly-transparent circle preserves a comfortable 44px tap target
    // without making the visible marker dominate the map.
    await controller.addCircleLayer(
      sourceId,
      _pointHitLayerId,
      const CircleLayerProperties(
        circleRadius: 22,
        circleColor: '#000666',
        circleOpacity: 0.01,
      ),
      filter: _pointFilter,
      enableInteraction: true,
    );
    await controller.addCircleLayer(
      sourceId,
      _pointShadowLayerId,
      const CircleLayerProperties(
        circleRadius: _pointShadowRadius,
        circleColor: 'rgba(0, 6, 102, 0.20)',
        circleBlur: 0.7,
      ),
      filter: _pointFilter,
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      sourceId,
      _pointLayerId,
      CircleLayerProperties(
        circleRadius: _pointRadius,
        circleColor: _mapColor(AppColors.primary),
        circleStrokeWidth: 2.25,
        circleStrokeColor: _mapColor(AppColors.surface),
      ),
      filter: _pointFilter,
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      sourceId,
      _restaurantGlyphLayerId,
      CircleLayerProperties(
        circleRadius: _restaurantGlyphRadius,
        circleColor: _mapColor(AppColors.surface),
      ),
      filter: _placeTypeFilter('restaurant'),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      sourceId,
      _cafeGlyphLayerId,
      CircleLayerProperties(
        circleRadius: _cafeGlyphRadius,
        circleColor: _mapColor(AppColors.surface),
      ),
      filter: _placeTypeFilter('cafe'),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      sourceId,
      _cafeGlyphCenterLayerId,
      CircleLayerProperties(
        circleRadius: 1.8,
        circleColor: _mapColor(AppColors.primary),
      ),
      filter: _placeTypeFilter('cafe'),
      enableInteraction: false,
    );
  }

  static Future<void> _addSelectedLayers(
    MapLibreMapController controller,
  ) async {
    await controller.addCircleLayer(
      _selectedSourceId,
      _selectedHaloLayerId,
      const CircleLayerProperties(
        circleRadius: 20,
        circleColor: 'rgba(212, 175, 55, 0.22)',
        circleBlur: 0.35,
      ),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _selectedSourceId,
      _selectedPointLayerId,
      CircleLayerProperties(
        circleRadius: 15,
        circleColor: _mapColor(AppColors.primary),
        circleStrokeWidth: 3,
        circleStrokeColor: _mapColor(AppColors.secondary),
      ),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _selectedSourceId,
      _selectedRestaurantGlyphLayerId,
      CircleLayerProperties(
        circleRadius: 4,
        circleColor: _mapColor(AppColors.surface),
      ),
      filter: _selectedPlaceTypeFilter('restaurant'),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _selectedSourceId,
      _selectedCafeGlyphLayerId,
      CircleLayerProperties(
        circleRadius: 5,
        circleColor: _mapColor(AppColors.surface),
      ),
      filter: _selectedPlaceTypeFilter('cafe'),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _selectedSourceId,
      _selectedCafeGlyphCenterLayerId,
      CircleLayerProperties(
        circleRadius: 2,
        circleColor: _mapColor(AppColors.primary),
      ),
      filter: _selectedPlaceTypeFilter('cafe'),
      enableInteraction: false,
    );
  }

  static bool contains(String layerId) {
    return layerId == clusterLayerId || layerId == _pointHitLayerId;
  }

  static bool isCluster(String layerId) => layerId == clusterLayerId;

  static Future<void> update(
    MapLibreMapController controller,
    List<RestaurantMapMarker> restaurants,
    String languageCode,
  ) {
    return controller.setGeoJsonSource(
      sourceId,
      featureCollection(restaurants, languageCode),
    );
  }

  static Future<void> updateSelected(
    MapLibreMapController controller,
    RestaurantMapMarker? restaurant,
    String languageCode,
  ) {
    return controller.setGeoJsonSource(
      _selectedSourceId,
      featureCollection(
        restaurant == null ? const [] : [restaurant],
        languageCode,
      ),
    );
  }

  @visibleForTesting
  static Map<String, dynamic> featureCollection(
    List<RestaurantMapMarker> restaurants,
    String languageCode,
  ) {
    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': [
        for (final restaurant in restaurants)
          <String, dynamic>{
            'type': 'Feature',
            'id': restaurant.id,
            'geometry': <String, dynamic>{
              'type': 'Point',
              'coordinates': [restaurant.longitude, restaurant.latitude],
            },
            'properties': <String, dynamic>{
              'restaurantId': restaurant.id,
              'name': restaurant.localizedName(languageCode),
              'placeType': restaurant.placeType.name,
              'sortKey': restaurant.hasThurayaStar ? 0 : 1,
            },
          },
      ],
    };
  }

  static List<Object> _placeTypeFilter(String placeType) {
    return [
      'all',
      _pointFilter,
      [
        '==',
        ['get', 'placeType'],
        placeType,
      ],
    ];
  }

  static List<Object> _selectedPlaceTypeFilter(String placeType) {
    return [
      '==',
      ['get', 'placeType'],
      placeType,
    ];
  }

  static const List<Object> _clusterRadius = [
    'interpolate',
    ['linear'],
    ['get', 'point_count'],
    2,
    17,
    10,
    20,
    50,
    24,
    200,
    28,
  ];

  static const List<Object> _clusterShadowRadius = [
    'interpolate',
    ['linear'],
    ['get', 'point_count'],
    2,
    20,
    10,
    23,
    50,
    27,
    200,
    31,
  ];

  static const List<Object> _clusterColor = [
    'step',
    ['get', 'point_count'],
    '#273079',
    10,
    '#111A70',
    30,
    '#000666',
  ];

  static const List<Object> _pointRadius = [
    'interpolate',
    ['linear'],
    ['zoom'],
    9.5,
    10.5,
    13,
    11.5,
    16,
    13,
  ];

  static const List<Object> _pointShadowRadius = [
    'interpolate',
    ['linear'],
    ['zoom'],
    9.5,
    13,
    13,
    14,
    16,
    15.5,
  ];

  static const List<Object> _restaurantGlyphRadius = [
    'interpolate',
    ['linear'],
    ['zoom'],
    9.5,
    2.6,
    16,
    3.5,
  ];

  static const List<Object> _cafeGlyphRadius = [
    'interpolate',
    ['linear'],
    ['zoom'],
    9.5,
    3.6,
    16,
    4.6,
  ];

  static String _mapColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
