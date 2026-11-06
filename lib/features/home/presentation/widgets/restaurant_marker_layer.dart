import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_images.dart';

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
  static const String clusterCountLayerId =
      'thuraya-restaurant-cluster-count-layer';
  static const String _pointHitLayerId = 'thuraya-restaurant-point-hit-layer';
  static const List<String> interactiveLayerIds = [
    clusterLayerId,
    _pointHitLayerId,
  ];
  static const String _pointShadowLayerId =
      'thuraya-restaurant-point-shadow-layer';
  static const String _pointLayerId = 'thuraya-restaurant-points-layer';
  static const String _restaurantGlyphLayerId =
      'thuraya-restaurant-point-glyph-layer';
  static const String _pointLabelLayerId =
      'thuraya-restaurant-point-label-layer';
  static const String _selectedHaloLayerId =
      'thuraya-selected-restaurant-halo-layer';
  static const String _selectedPointLayerId =
      'thuraya-selected-restaurant-point-layer';
  static const String _selectedRestaurantGlyphLayerId =
      'thuraya-selected-restaurant-glyph-layer';
  static const double clusterMaxZoom = 14;
  static const double individualFocusZoom = 15.5;

  static const List<Object> _clusterFilter = ['has', 'point_count'];
  static const List<Object> _pointFilter = [
    '!',
    ['has', 'point_count'],
  ];

  static Future<void> install(
    MapLibreMapController controller, {
    double imagePixelRatio = 1,
  }) async {
    final images = await RestaurantMarkerImages.load();
    for (final image in images.entries) {
      await controller.addImage(image.key, image.value);
    }
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
    await _addPointLayers(controller, imagePixelRatio);
    await _addSelectedLayers(controller, imagePixelRatio);
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
    // Render counts in the map itself so they cannot drift off their circles
    // during camera animations or on screens with different pixel densities.
    await controller.addSymbolLayer(
      sourceId,
      clusterCountLayerId,
      SymbolLayerProperties(
        textField: const [
          'to-string',
          ['get', 'point_count_abbreviated'],
        ],
        textFont: const ['Noto Sans Bold'],
        textSize: 13.5,
        textColor: _mapColor(AppColors.onPrimary),
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      filter: _clusterFilter,
      enableInteraction: false,
    );
  }

  static Future<void> _addPointLayers(
    MapLibreMapController controller,
    double imagePixelRatio,
  ) async {
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
    await controller.addSymbolLayer(
      sourceId,
      _restaurantGlyphLayerId,
      SymbolLayerProperties(
        iconImage: _categoryIcon,
        iconSize: [
          'interpolate',
          ['linear'],
          ['zoom'],
          9.5,
          20 * imagePixelRatio / RestaurantMarkerImages.imageSize,
          16,
          22 * imagePixelRatio / RestaurantMarkerImages.imageSize,
        ],
        iconAnchor: 'center',
        iconPitchAlignment: 'viewport',
        iconRotationAlignment: 'viewport',
        // Circles are always drawn: their category glyphs must remain visible
        // too. Density is managed by the clustered source, not icon collisions.
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      filter: _pointFilter,
      enableInteraction: false,
    );
    await controller.addSymbolLayer(
      sourceId,
      _pointLabelLayerId,
      SymbolLayerProperties(
        symbolPlacement: 'point',
        symbolSortKey: const ['get', 'sortKey'],
        textField: const ['get', 'name'],
        textFont: const ['Noto Sans Regular'],
        textSize: _labelTextSize,
        textMaxWidth: 12,
        textLineHeight: 1.1,
        textJustify: 'auto',
        // Prefer either side of the unchanged marker, then fall back above
        // or below when MapLibre's collision detection needs more room.
        textVariableAnchor: const ['left', 'right', 'top', 'bottom'],
        textRadialOffset: 1.8,
        textPadding: 3,
        textAllowOverlap: false,
        textIgnorePlacement: false,
        textColor: _mapColor(AppColors.textPrimary),
        textHaloColor: _mapColor(AppColors.surface),
        textHaloWidth: 1.5,
        textHaloBlur: 0.35,
      ),
      filter: _pointFilter,
      enableInteraction: false,
    );
  }

  static Future<void> _addSelectedLayers(
    MapLibreMapController controller,
    double imagePixelRatio,
  ) async {
    await controller.addCircleLayer(
      _selectedSourceId,
      _selectedHaloLayerId,
      const CircleLayerProperties(
        circleRadius: 25,
        circleColor: 'rgba(212, 175, 55, 0.22)',
        circleBlur: 0.35,
      ),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _selectedSourceId,
      _selectedPointLayerId,
      CircleLayerProperties(
        circleRadius: 20,
        circleColor: _mapColor(AppColors.secondary),
        circleStrokeWidth: 3,
        circleStrokeColor: _mapColor(AppColors.surface),
      ),
      enableInteraction: false,
    );
    await controller.addSymbolLayer(
      _selectedSourceId,
      _selectedRestaurantGlyphLayerId,
      SymbolLayerProperties(
        iconImage: _categoryIcon,
        iconSize: 26 * imagePixelRatio / RestaurantMarkerImages.imageSize,
        iconAnchor: 'center',
        iconPitchAlignment: 'viewport',
        iconRotationAlignment: 'viewport',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
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

  // placeType is supplied by the backend from all assigned categories. Award
  // status only affects label priority and never changes the business icon.
  static const List<Object> _categoryIcon = [
    'match',
    ['get', 'placeType'],
    'cafe',
    RestaurantMarkerImages.cafe,
    RestaurantMarkerImages.restaurant,
  ];

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
    14,
    13,
    15,
    16,
    16,
  ];

  static const List<Object> _pointShadowRadius = [
    'interpolate',
    ['linear'],
    ['zoom'],
    9.5,
    16.5,
    13,
    17.5,
    16,
    18.5,
  ];

  static const List<Object> _labelTextSize = [
    'interpolate',
    ['linear'],
    ['zoom'],
    9.5,
    11,
    13,
    12,
    16,
    13,
  ];

  static String _mapColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
