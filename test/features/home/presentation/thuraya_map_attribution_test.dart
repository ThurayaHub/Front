import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/features/home/presentation/widgets/thuraya_map.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/maplibre_gl_0');
  late MapLibrePlatform Function() previousPlatformFactory;

  setUp(() async {
    previousPlatformFactory = MapLibrePlatform.createInstance;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
    final platform = MapLibreMethodChannel();
    await platform.initPlatform(0);
    MapLibrePlatform.createInstance = () => platform;
  });

  tearDown(() {
    MapLibrePlatform.createInstance = previousPlatformFactory;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('shows credits for five seconds then keeps native attribution', (
    tester,
  ) async {
    final map = await _loadMap(tester);
    final notice = find.byKey(const ValueKey('map-attribution-notice'));
    expect(notice, findsOneWidget);
    expect(find.textContaining('© OpenStreetMap contributors'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4999));
    expect(notice, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(notice, findsNothing);

    final currentMap = tester.widget<MapLibreMap>(find.byType(MapLibreMap));
    expect(
      currentMap.attributionButtonPosition,
      AttributionButtonPosition.bottomLeft,
    );
    expect(currentMap.attributionButtonColor, AppColors.primary);
    expect(currentMap.attributionButtonMargins, const Point(8, 98));

    // Style reloads must not bring back the dismissed strip.
    map.onStyleLoadedCallback!();
    await tester.pumpAndSettle();
    expect(notice, findsNothing);
  });

  testWidgets(
    'map tap dismisses the initial credits without changing gestures',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final map = await _loadMap(tester);
      final notice = find.byKey(const ValueKey('map-attribution-notice'));
      expect(Directionality.of(tester.element(notice)), TextDirection.rtl);
      expect(tester.getRect(notice).left, greaterThanOrEqualTo(44));
      expect(tester.getRect(notice).right, lessThanOrEqualTo(276));
      expect(tester.takeException(), isNull);

      map.onMapClick!(const Point(160, 320), const LatLng(24.71, 46.67));
      await tester.pump();
      expect(notice, findsNothing);
      expect(map.zoomGesturesEnabled, isTrue);
      expect(map.scrollGesturesEnabled, isTrue);
      expect(map.doubleClickZoomEnabled, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<MapLibreMap> _loadMap(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: ThurayaMap(restaurants: [], padding: EdgeInsets.only(bottom: 90)),
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
  addTearDown(controller.dispose);
  map.onMapCreated!(controller);
  map.onStyleLoadedCallback!();
  await tester.pump();
  return map;
}
