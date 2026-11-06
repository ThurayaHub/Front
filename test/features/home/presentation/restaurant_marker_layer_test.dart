import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_layer.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_images.dart';

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
      (call) =>
          call.method == 'symbolLayer#add' &&
          (call.arguments as Map)['layerId'] ==
              'thuraya-restaurant-point-label-layer',
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

    final countCall = calls.singleWhere(
      (call) =>
          call.method == 'symbolLayer#add' &&
          (call.arguments as Map)['layerId'] ==
              RestaurantMarkerLayer.clusterCountLayerId,
    );
    final countArguments = countCall.arguments as Map;
    expect(countArguments['enableInteraction'], isFalse);
    expect(jsonDecode(countArguments['filter'] as String), [
      'has',
      'point_count',
    ]);
    final countProperties = countArguments['properties'] as Map;
    expect(countProperties['text-color'], '#ffffff');
    expect(countProperties['text-allow-overlap'], isTrue);
    expect(countProperties['text-field'], [
      'to-string',
      ['get', 'point_count_abbreviated'],
    ]);

    final imageCalls = calls
        .where((call) => call.method == 'style#addImage')
        .toList();
    expect(imageCalls.map((call) => (call.arguments as Map)['name']), [
      RestaurantMarkerImages.restaurant,
      RestaurantMarkerImages.cafe,
    ]);
    for (final call in imageCalls) {
      final image = call.arguments as Map;
      expect(image['sdf'], isFalse);
      expect((image['bytes'] as List<int>).take(8), [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
    }
    Map properties(String id, String method) =>
        calls
                .where((call) => call.method == method)
                .map((call) => call.arguments as Map)
                .singleWhere((args) => args['layerId'] == id)['properties']
            as Map;
    final categoryIcon = properties(
      'thuraya-restaurant-point-glyph-layer',
      'symbolLayer#add',
    );
    final selectedIcon = properties(
      'thuraya-selected-restaurant-glyph-layer',
      'symbolLayer#add',
    );
    expect(categoryIcon['icon-image'], [
      'match',
      ['get', 'placeType'],
      'cafe',
      RestaurantMarkerImages.cafe,
      RestaurantMarkerImages.restaurant,
    ]);
    expect(selectedIcon['icon-image'], categoryIcon['icon-image']);
    expect(categoryIcon['icon-allow-overlap'], isTrue);
    final point = properties(
      'thuraya-restaurant-points-layer',
      'circleLayer#add',
    );
    final selected = properties(
      'thuraya-selected-restaurant-point-layer',
      'circleLayer#add',
    );
    expect(point['circle-color'], '#000666');
    expect(point['circle-stroke-color'], '#ffffff');
    expect(selected['circle-color'], '#d4af37');
    expect(selected['circle-stroke-color'], '#ffffff');
    expect(
      selected['circle-radius'],
      greaterThan((point['circle-radius'] as List).last as num),
    );

    // Switching selections touches only the tiny selected source, never images
    // or the clustered restaurant source.
    calls.clear();
    await RestaurantMarkerLayer.updateSelected(controller, _restaurant, 'ar');
    await RestaurantMarkerLayer.updateSelected(controller, null, 'ar');
    expect(calls.map((call) => call.method), [
      'source#setGeoJson',
      'source#setGeoJson',
    ]);
    expect(
      calls.every(
        (call) =>
            (call.arguments as Map)['sourceId'] ==
            'thuraya-selected-restaurant-source',
      ),
      isTrue,
    );

    controller.dispose();
  });

  test(
    'normalizes native image density without changing marker geometry',
    () async {
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
          target: LatLng(24.71, 46.67),
          zoom: 16,
        ),
        annotationOrder: const [],
        annotationConsumeTapEvents: const [],
      );
      await RestaurantMarkerLayer.install(controller, imagePixelRatio: 3);
      final selected = calls.singleWhere(
        (call) =>
            call.method == 'symbolLayer#add' &&
            (call.arguments as Map)['layerId'] ==
                'thuraya-selected-restaurant-glyph-layer',
      );
      expect(
        ((selected.arguments as Map)['properties'] as Map)['icon-size'],
        26 * 3 / 72,
      );
      controller.dispose();
    },
  );

  test(
    'reuses the same two distinct bundled glyph buffers across map instances',
    () async {
      final first = await RestaurantMarkerImages.load();
      final second = await RestaurantMarkerImages.load();
      expect(identical(first, second), isTrue);
      expect(first.keys, [
        RestaurantMarkerImages.restaurant,
        RestaurantMarkerImages.cafe,
      ]);
      expect(
        first[RestaurantMarkerImages.restaurant],
        isNot(orderedEquals(first[RestaurantMarkerImages.cafe]!)),
      );
    },
  );

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
