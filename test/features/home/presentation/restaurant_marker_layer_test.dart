import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mapChannel = MethodChannel('plugins.flutter.io/maplibre_gl_0');
  late MapLibrePlatform Function() previousMapPlatformFactory;

  setUp(() {
    previousMapPlatformFactory = MapLibrePlatform.createInstance;
  });

  tearDown(() {
    MapLibrePlatform.createInstance = previousMapPlatformFactory;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mapChannel, null);
  });

  test('installs a clustered source with dedicated tap layers', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mapChannel, (call) async {
          calls.add(call);
          return null;
        });

    final platform = MapLibreMethodChannel();
    await platform.initPlatform(0);
    final controller = MapLibreMapController(
      maplibrePlatform: platform,
      initialCameraPosition: const CameraPosition(
        target: LatLng(24.7136, 46.6753),
        zoom: 12.5,
      ),
      annotationOrder: const [],
      annotationConsumeTapEvents: const [],
    );

    await RestaurantMarkerLayer.install(controller);

    final sourceCall = calls.singleWhere(
      (call) => call.method == 'style#addSource',
    );
    final sourceArguments = Map<String, dynamic>.from(
      sourceCall.arguments as Map,
    );
    final sourceProperties = Map<String, dynamic>.from(
      sourceArguments['properties'] as Map,
    );
    expect(sourceArguments['sourceId'], RestaurantMarkerLayer.sourceId);
    expect(sourceProperties['cluster'], isTrue);
    expect(sourceProperties['clusterRadius'], 54);
    expect(
      sourceProperties['clusterMaxZoom'],
      RestaurantMarkerLayer.clusterMaxZoom,
    );

    final interactiveCircleLayers = calls
        .where((call) => call.method == 'circleLayer#add')
        .map((call) => Map<String, dynamic>.from(call.arguments as Map))
        .where((arguments) => arguments['enableInteraction'] == true)
        .map((arguments) => arguments['layerId'])
        .toSet();
    expect(interactiveCircleLayers, {
      'thuraya-restaurant-clusters-layer',
      'thuraya-restaurant-point-hit-layer',
    });

    final labelCall = calls.singleWhere(
      (call) => call.method == 'symbolLayer#add',
    );
    final labelArguments = Map<String, dynamic>.from(
      labelCall.arguments as Map,
    );
    final labelProperties = Map<String, dynamic>.from(
      labelArguments['properties'] as Map,
    );
    expect(labelArguments['layerId'], 'thuraya-restaurant-point-label-layer');
    expect(labelArguments['sourceId'], RestaurantMarkerLayer.sourceId);
    expect(labelArguments['enableInteraction'], isFalse);
    expect(jsonDecode(labelArguments['filter'] as String), [
      '!',
      ['has', 'point_count'],
    ]);
    expect(labelProperties['text-field'], ['get', 'name']);
    expect(labelProperties['text-variable-anchor'], [
      'left',
      'right',
      'top',
      'bottom',
    ]);
    expect(labelProperties['text-allow-overlap'], isFalse);
    expect(labelProperties['symbol-sort-key'], ['get', 'sortKey']);

    controller.dispose();
  });

  test('builds localized point features for filtered marker updates', () {
    final collection = RestaurantMarkerLayer.featureCollection(const [
      _restaurant,
    ], 'ar');
    final features = collection['features'] as List<dynamic>;
    final feature = Map<String, dynamic>.from(features.single as Map);
    final geometry = Map<String, dynamic>.from(feature['geometry'] as Map);
    final properties = Map<String, dynamic>.from(feature['properties'] as Map);

    expect(feature['id'], 9);
    expect(geometry['coordinates'], [46.67, 24.71]);
    expect(properties['restaurantId'], 9);
    expect(properties['name'], 'بيت البرجر');
    expect(properties['placeType'], 'cafe');
    expect(properties['sortKey'], 0);

    expect(jsonEncode(collection), contains('FeatureCollection'));
  });

  test('uses the English restaurant name for English marker labels', () {
    final collection = RestaurantMarkerLayer.featureCollection(const [
      _restaurant,
    ], 'en');
    final features = collection['features'] as List<dynamic>;
    final feature = Map<String, dynamic>.from(features.single as Map);
    final properties = Map<String, dynamic>.from(feature['properties'] as Map);

    expect(properties['name'], 'Burger House');
  });
}

const _restaurant = RestaurantMapMarker(
  id: 9,
  name: 'Burger House',
  nameArabic: 'بيت البرجر',
  latitude: 24.71,
  longitude: 46.67,
  placeType: RestaurantMapPlaceType.cafe,
  priceLevelId: 2,
  hasThurayaStar: true,
  userRatingAverage: 4.5,
  reviewCount: 12,
  mainPhotoUrl: null,
  primaryCategoryId: 6,
  primaryCategoryName: 'Cafe',
);
