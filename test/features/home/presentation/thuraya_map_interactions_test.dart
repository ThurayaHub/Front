import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/features/home/models/restaurant_map_marker.dart';
import 'package:thuraya/features/home/presentation/widgets/restaurant_marker_layer.dart';
import 'package:thuraya/features/home/presentation/widgets/thuraya_map.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/features/restaurant_details/services/restaurant_details_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/maplibre_gl_0');
  late MapLibrePlatform Function() previousFactory;
  late List<MethodCall> calls;
  late Future<Object?> Function(MethodCall) respond;
  late List<Map<String, dynamic>> hitFeatures;
  late List<Map<String, dynamic>> leaves;

  setUp(() async {
    calls = [];
    hitFeatures = [];
    leaves = [_feature(_restaurant), _feature(_cafe)];
    previousFactory = MapLibrePlatform.createInstance;
    respond = (call) async => switch (call.method) {
      'map#queryRenderedFeatures' => _featuresReply(hitFeatures),
      'source#getClusterExpansionZoom' => 14,
      'source#getClusterLeaves' => _featuresReply(leaves),
      'camera#animate' || 'camera#move' => true,
      _ => null,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return respond(call);
        });
    final platform = MapLibreMethodChannel();
    await platform.initPlatform(0);
    MapLibrePlatform.createInstance = () => platform;
  });

  tearDown(() {
    MapLibrePlatform.createInstance = previousFactory;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  List<MethodCall> cameraCalls() =>
      calls.where((c) => c.method.startsWith('camera#')).toList();

  testWidgets(
    'search fits once; selection, refresh and manual movement stay stable',
    (tester) async {
      final harness = await _mount(
        tester,
        const _Config(fit: true, request: 1),
      );
      expect(cameraCalls(), hasLength(1));
      calls.clear();
      harness.config.value = const _Config(
        fit: true,
        request: 1,
        selected: _restaurant,
      );
      await tester.pumpAndSettle();
      expect(cameraCalls(), hasLength(1));
      expect(
        _cameraUpdate(cameraCalls().single)[2] as num,
        greaterThanOrEqualTo(15.5),
      );
      calls.clear();

      harness.map(tester).onCameraMove!(
        const CameraPosition(target: LatLng(24.72, 46.68), zoom: 17),
      );
      harness.map(tester).onCameraIdle!();
      harness.config.value = _Config(
        fit: true,
        request: 1,
        selected: _restaurant,
        places: [_cafe],
      );
      await tester.pumpAndSettle();
      expect(cameraCalls(), isEmpty);
      expect(
        find.byKey(const ValueKey('restaurant-preview-9')),
        findsOneWidget,
      );
      expect(_selectedIds(calls).last, [9]);
      await _dispose(tester, harness);
    },
  );

  testWidgets('an in-flight result fit cannot override a newer selection', (
    tester,
  ) async {
    final harness = await _mount(tester, const _Config());
    calls.clear();
    final blocked = Completer<Object?>();
    final normal = respond;
    var block = true;
    respond = (call) {
      if (block &&
          call.method == 'source#setGeoJson' &&
          (call.arguments as Map)['sourceId'] ==
              RestaurantMarkerLayer.sourceId) {
        block = false;
        return blocked.future;
      }
      return normal(call);
    };
    harness.config.value = _Config(
      fit: true,
      request: 1,
      places: [_restaurant, _cafe],
    );
    await tester.pump();
    harness.config.value = const _Config(
      fit: true,
      request: 1,
      selected: _cafe,
    );
    await tester.pump();
    blocked.complete(null);
    await tester.pumpAndSettle();
    expect(cameraCalls(), hasLength(1));
    expect(_cameraUpdate(cameraCalls().single)[1], [
      _cafe.latitude,
      _cafe.longitude,
    ]);
    expect(_selectedIds(calls).last, [10]);
    await _dispose(tester, harness);
  });

  testWidgets('manual interaction cancels a search fit awaiting results', (
    tester,
  ) async {
    final harness = await _mount(tester, const _Config(request: 1));
    calls.clear();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('home-map'))),
    );
    await gesture.moveBy(const Offset(35, 0));
    await gesture.up();
    harness.config.value = _Config(
      fit: true,
      request: 1,
      places: [_restaurant, _cafe],
    );
    await tester.pumpAndSettle();
    expect(cameraCalls(), isEmpty);
    await _dispose(tester, harness);
  });

  testWidgets(
    'rapid choices keep only the latest highlight; parent echo adds no animation',
    (tester) async {
      final harness = await _mount(tester, const _Config());
      calls.clear();
      harness.config.value = const _Config(selected: _restaurant);
      await tester.pump();
      harness.config.value = const _Config(selected: _cafe);
      await tester.pumpAndSettle();
      expect(_cameraUpdate(cameraCalls().last)[1], [
        _cafe.latitude,
        _cafe.longitude,
      ]);
      expect(_selectedIds(calls).last, [10]);
      calls.clear();
      hitFeatures = [_feature(_restaurant)];
      harness.tapFeature('9', RestaurantMarkerLayer.interactiveLayerIds.last);
      await tester.pumpAndSettle();
      expect(cameraCalls(), hasLength(1));
      harness.config.value = const _Config(selected: _restaurant);
      await tester.pumpAndSettle();
      expect(cameraCalls(), hasLength(1));
      await _dispose(tester, harness);
    },
  );

  testWidgets(
    'mixed cluster fits actual leaves in one animation, then a marker selects',
    (tester) async {
      final harness = await _mount(tester, const _Config());
      calls.clear();
      hitFeatures = [_cluster];
      harness.tapFeature('123', RestaurantMarkerLayer.clusterLayerId);
      await tester.pumpAndSettle();
      expect(cameraCalls(), hasLength(1));
      final update = _cameraUpdate(cameraCalls().single);
      expect(update[0], 'newLatLngZoom');
      expect(update[2] as num, greaterThan(15));
      expect((update[1] as List)[1] as num, closeTo(46.67015, 0.001));
      expect(
        calls
            .singleWhere((c) => c.method == 'source#getClusterLeaves')
            .arguments,
        {
          'sourceId': RestaurantMarkerLayer.sourceId,
          'clusterId': 123,
          'limit': 2,
          'offset': 0,
        },
      );
      calls.clear();
      hitFeatures = [_feature(_cafe)];
      harness.tapFeature('10', RestaurantMarkerLayer.interactiveLayerIds.last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('restaurant-preview-10')),
        findsOneWidget,
      );
      expect(cameraCalls(), hasLength(1));
      expect(harness.map(tester).featureTapsTriggersMapClick, isFalse);
      expect(harness.map(tester).trackCameraPosition, isTrue);
      await _dispose(tester, harness);
    },
  );

  for (final locale in ['ar', 'en']) {
    testWidgets(
      'co-located venues offer an accessible selection list in $locale',
      (tester) async {
        final colocated = RestaurantMapMarker(
          id: 10,
          name: 'Coffee',
          nameArabic: 'قهوة',
          latitude: _restaurant.latitude,
          longitude: _restaurant.longitude,
          placeType: RestaurantMapPlaceType.cafe,
          hasThurayaStar: false,
        );
        final harness = await _mount(
          tester,
          _Config(places: [_restaurant, colocated]),
          locale: locale,
        );
        leaves = [_feature(_restaurant), _feature(colocated)];
        hitFeatures = [_cluster];
        calls.clear();
        harness.tapFeature('123', RestaurantMarkerLayer.clusterLayerId);
        await tester.pumpAndSettle();
        final choice = find.byKey(const ValueKey('map-place-choice-10'));
        expect(choice, findsOneWidget);
        expect(
          Directionality.of(tester.element(choice)),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(find.byIcon(Icons.local_cafe_rounded), findsOneWidget);
        expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
        expect(cameraCalls(), isEmpty);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('restaurant-preview-10')),
          findsOneWidget,
        );
        expect(cameraCalls(), hasLength(1));
        await _dispose(tester, harness);
      },
    );
  }

  testWidgets(
    'late cluster lookup cannot override a newer restaurant selection',
    (tester) async {
      final harness = await _mount(tester, const _Config());
      calls.clear();
      hitFeatures = [_cluster];
      final blocked = Completer<Object?>();
      final normal = respond;
      respond = (call) => call.method == 'source#getClusterLeaves'
          ? blocked.future
          : normal(call);
      harness.tapFeature('123', RestaurantMarkerLayer.clusterLayerId);
      await tester.pump();
      harness.config.value = const _Config(selected: _cafe);
      await tester.pump();
      blocked.complete(_featuresReply(leaves));
      await tester.pumpAndSettle();
      expect(cameraCalls(), hasLength(1));
      expect(_cameraUpdate(cameraCalls().single)[1], [
        _cafe.latitude,
        _cafe.longitude,
      ]);
      expect(
        find.byKey(const ValueKey('restaurant-preview-10')),
        findsOneWidget,
      );
      await _dispose(tester, harness);
    },
  );

  testWidgets('rapid marker taps ignore a late hit-test response', (
    tester,
  ) async {
    final harness = await _mount(tester, const _Config());
    calls.clear();
    final blocked = Completer<Object?>();
    final normal = respond;
    var first = true;
    respond = (call) {
      if (call.method == 'map#queryRenderedFeatures' && first) {
        first = false;
        return blocked.future;
      }
      return normal(call);
    };
    harness.tapFeature('9', RestaurantMarkerLayer.interactiveLayerIds.last);
    await tester.pump();
    hitFeatures = [_feature(_cafe)];
    harness.tapFeature('10', RestaurantMarkerLayer.interactiveLayerIds.last);
    await tester.pump();
    blocked.complete(_featuresReply([_feature(_restaurant)]));
    await tester.pumpAndSettle();
    expect(cameraCalls(), hasLength(1));
    expect(_cameraUpdate(cameraCalls().single)[1], [
      _cafe.latitude,
      _cafe.longitude,
    ]);
    expect(_selectedIds(calls).last, [10]);
    await _dispose(tester, harness);
  });

  testWidgets(
    'overlapping individual hit targets offer a choice instead of hiding venues',
    (tester) async {
      final harness = await _mount(tester, const _Config());
      hitFeatures = [_feature(_restaurant), _feature(_cafe)];
      harness.map(tester).onCameraMove!(
        const CameraPosition(target: LatLng(24.71, 46.67), zoom: 20),
      );
      harness.tapFeature('9', RestaurantMarkerLayer.interactiveLayerIds.last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-place-choice-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('map-place-choice-10')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('map-place-choice-10')));
      await tester.pumpAndSettle();
      expect(_cameraUpdate(cameraCalls().last)[2], 20);
      await _dispose(tester, harness);
    },
  );
}

const _restaurant = RestaurantMapMarker(
  id: 9,
  name: 'Restaurant',
  nameArabic: 'مطعم',
  latitude: 24.71,
  longitude: 46.67,
  hasThurayaStar: false,
);
const _cafe = RestaurantMapMarker(
  id: 10,
  name: 'Coffee',
  nameArabic: 'قهوة',
  latitude: 24.7103,
  longitude: 46.6703,
  placeType: RestaurantMapPlaceType.cafe,
  hasThurayaStar: true,
);
const _cluster = {
  'type': 'Feature',
  'id': 123,
  'properties': {'cluster': true, 'cluster_id': 123, 'point_count': 2},
  'geometry': {
    'type': 'Point',
    'coordinates': [46.67015, 24.71015],
  },
};

Map<String, dynamic> _feature(RestaurantMapMarker place) =>
    (RestaurantMarkerLayer.featureCollection([place], 'en')['features'] as List)
            .single
        as Map<String, dynamic>;
Map<String, dynamic> _featuresReply(List<Map<String, dynamic>> features) => {
  'features': features.map(jsonEncode).toList(),
};
List<dynamic> _cameraUpdate(MethodCall call) =>
    (call.arguments as Map)['cameraUpdate'] as List;
List<List<dynamic>> _selectedIds(List<MethodCall> calls) => calls
    .where(
      (c) =>
          c.method == 'source#setGeoJson' &&
          (c.arguments as Map)['sourceId'] ==
              'thuraya-selected-restaurant-source',
    )
    .map(
      (c) =>
          ((jsonDecode((c.arguments as Map)['geojson'] as String)
                      as Map)['features']
                  as List)
              .map((f) => (f as Map)['id'])
              .toList(),
    )
    .toList();

class _Config {
  const _Config({
    this.places = const [_restaurant, _cafe],
    this.selected,
    this.fit = false,
    this.request = 0,
  });
  final List<RestaurantMapMarker> places;
  final RestaurantMapMarker? selected;
  final bool fit;
  final int request;
}

class _Harness {
  _Harness(this.config, this.controller);
  final ValueNotifier<_Config> config;
  final MapLibreMapController controller;
  MapLibreMap map(WidgetTester tester) =>
      tester.widget<MapLibreMap>(find.byType(MapLibreMap));
  void tapFeature(String id, String layer) {
    for (final callback in controller.onFeatureTapped.toList()) {
      callback(
        const Point(160.0, 300.0),
        const LatLng(24.71, 46.67),
        id,
        layer,
        null,
      );
    }
  }
}

Future<_Harness> _mount(
  WidgetTester tester,
  _Config initial, {
  String locale = 'ar',
}) async {
  final config = ValueNotifier(initial);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ValueListenableBuilder<_Config>(
        valueListenable: config,
        builder: (context, state, _) => Scaffold(
          body: ThurayaMap(
            restaurants: state.places,
            selectedRestaurant: state.selected,
            fitRestaurants: state.fit,
            fitRequestId: state.request,
            restaurantDetailsService: _NoDetails(),
            padding: const EdgeInsets.only(top: 100, bottom: 90),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final map = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
  final platform = MapLibreMethodChannel();
  await platform.initPlatform(0);
  final controller = MapLibreMapController(
    maplibrePlatform: platform,
    initialCameraPosition: map.initialCameraPosition!,
    annotationOrder: const [],
    annotationConsumeTapEvents: const [],
  );
  map.onMapCreated!(controller);
  map.onStyleLoadedCallback!();
  await tester.pumpAndSettle();
  return _Harness(config, controller);
}

Future<void> _dispose(WidgetTester tester, _Harness harness) async {
  await tester.pumpWidget(const SizedBox.shrink());
  harness.controller.dispose();
  harness.config.dispose();
  expect(tester.takeException(), isNull);
}

class _NoDetails extends RestaurantDetailsService {
  @override
  Future<RestaurantDetailsDto> getDetails(int id) async =>
      throw StateError('No details in map interaction tests');
}
