import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/presentation/widgets/thuraya_map.dart';
import 'package:thuraya/features/home/services/current_location_service.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mapChannel = MethodChannel('plugins.flutter.io/maplibre_gl_0');
  late MapLibrePlatform Function() previousMapPlatformFactory;
  late List<MethodCall> mapCalls;

  setUp(() async {
    mapCalls = <MethodCall>[];
    previousMapPlatformFactory = MapLibrePlatform.createInstance;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mapChannel, (call) async {
          mapCalls.add(call);
          return call.method == 'camera#move' ? true : null;
        });

    final platform = MapLibreMethodChannel();
    await platform.initPlatform(0);
    MapLibrePlatform.createInstance = () => platform;
  });

  tearDown(() {
    MapLibrePlatform.createInstance = previousMapPlatformFactory;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mapChannel, null);
  });

  testWidgets('shows one location button and snaps to current location', (
    tester,
  ) async {
    const coordinates = CurrentCoordinates(
      latitude: 24.7136,
      longitude: 46.6753,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ThurayaMap(
            restaurants: [],
            locationService: _FixedLocationService(coordinates),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final locationButton = find.byKey(const ValueKey('home-current-location'));
    expect(locationButton, findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

    var map = tester.widget<MapLibreMap>(
      find.byKey(const ValueKey('home-map')),
    );
    expect(map.myLocationEnabled, isFalse);

    final platform = MapLibreMethodChannel();
    await platform.initPlatform(0);
    final controller = MapLibreMapController(
      maplibrePlatform: platform,
      initialCameraPosition: map.initialCameraPosition!,
      annotationOrder: const [],
      annotationConsumeTapEvents: const [],
    );
    addTearDown(controller.dispose);
    map.onMapCreated!(controller);
    await tester.pump();

    mapCalls.clear();
    await tester.tap(locationButton);
    await tester.pumpAndSettle();

    final cameraCall = mapCalls.singleWhere(
      (call) => call.method == 'camera#move',
    );
    final cameraArguments = Map<String, dynamic>.from(
      cameraCall.arguments as Map,
    );
    final cameraUpdate = cameraArguments['cameraUpdate'] as List<dynamic>;
    final target = cameraUpdate[1] as List<dynamic>;
    expect(cameraUpdate[0], 'newLatLngZoom');
    expect(target[0], closeTo(coordinates.latitude, 0.000001));
    expect(target[1], closeTo(coordinates.longitude, 0.000001));
    expect(cameraUpdate[2], SupportedMapRegions.riyadh.currentLocationZoom);
    expect(mapCalls.where((call) => call.method == 'camera#animate'), isEmpty);

    map = tester.widget<MapLibreMap>(find.byKey(const ValueKey('home-map')));
    expect(map.myLocationEnabled, isFalse);
    expect(locationButton, findsOneWidget);
  });
}

class _FixedLocationService extends CurrentLocationService {
  const _FixedLocationService(this.coordinates);

  final CurrentCoordinates coordinates;

  @override
  Future<CurrentCoordinates> getCurrentCoordinates() async => coordinates;
}
