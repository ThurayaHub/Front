import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_images.dart';

abstract final class RestaurantMarkerLayer {
  static const String sourceId = 'thuraya-restaurants-source';
  static const String _circleLayerId = 'thuraya-restaurant-circles-layer';
  static const String _restaurantLayerId = 'thuraya-restaurants-layer';
  static const String _cafeLayerId = 'thuraya-cafes-layer';
  static const String _restaurantIconId = 'thuraya-restaurant-marker';
  static const String _cafeIconId = 'thuraya-cafe-marker';

  static Future<void> install(MapLibreMapController controller) async {
    await controller.addImage(
      _restaurantIconId,
      RestaurantMarkerImages.restaurant,
    );
    await controller.addImage(_cafeIconId, RestaurantMarkerImages.cafe);
    await controller.addGeoJsonSource(sourceId, _featureCollection(const [], 'en'));
    await controller.addCircleLayer(
      sourceId,
      _circleLayerId,
      CircleLayerProperties(
        circleRadius: 11,
        circleColor: _mapColor(AppColors.primary),
        circleStrokeWidth: 2,
        circleStrokeColor: _mapColor(AppColors.surface),
      ),
      enableInteraction: true,
    );
    await controller.addSymbolLayer(
      sourceId,
      _restaurantLayerId,
      _layerProperties(),
      minzoom: 10.25,
      filter: const [
        '==',
        ['get', 'placeType'],
        'restaurant',
      ],
      enableInteraction: true,
    );
    await controller.addSymbolLayer(
      sourceId,
      _cafeLayerId,
      _layerProperties(),
      minzoom: 10.25,
      filter: const [
        '==',
        ['get', 'placeType'],
        'cafe',
      ],
      enableInteraction: true,
    );
  }

  static bool contains(String layerId) {
    return layerId == _circleLayerId ||
        layerId == _restaurantLayerId ||
        layerId == _cafeLayerId;
  }

  static String iconIdFor(RestaurantMapPlaceType placeType) {
    return placeType == RestaurantMapPlaceType.cafe
        ? _cafeIconId
        : _restaurantIconId;
  }

  static Future<void> update(
    MapLibreMapController controller,
    List<RestaurantMapMarker> restaurants,
    String languageCode,
  ) {
    return controller.setGeoJsonSource(
      sourceId,
      _featureCollection(restaurants, languageCode),
    );
  }

  static Map<String, dynamic> _featureCollection(
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

  static SymbolLayerProperties _layerProperties() {
    return SymbolLayerProperties(
      symbolAvoidEdges: true,
      symbolSortKey: const ['get', 'sortKey'],
      textField: const ['get', 'name'],
      textFont: const ['Noto Sans Regular'],
      textSize: 12.5,
      textMaxWidth: 14,
      textLineHeight: 1.05,
      textLetterSpacing: 0.01,
      textJustify: 'auto',
      textVariableAnchor: const ['left', 'right', 'top', 'bottom'],
      textRadialOffset: 1.55,
      textRotationAlignment: 'viewport',
      textWritingMode: const ['horizontal'],
      textColor: _mapColor(AppColors.primary),
      textHaloColor: _mapColor(AppColors.surface),
      textHaloWidth: 1.5,
      textHaloBlur: 0.3,
      textPadding: 3,
      textAllowOverlap: false,
      textIgnorePlacement: false,
      textOptional: true,
    );
  }

  static String _mapColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }
}
