import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:thuraya/app.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/theme/app_colors.dart';
import 'package:thuraya/features/home/models/supported_map_region.dart';
import 'package:thuraya/features/home/presentation/widgets/thuraya_map.dart';
import 'package:thuraya/features/restaurants/data/mock_restaurants.dart';
import 'package:thuraya/features/restaurants/models/restaurant.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mapChannel = MethodChannel('plugins.flutter.io/maplibre_gl_0');
  late MapLibrePlatform Function() previousMapPlatformFactory;

  setUp(() async {
    previousMapPlatformFactory = MapLibrePlatform.createInstance;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mapChannel, (_) async => null);

    final platform = MapLibreMethodChannel();
    await platform.initPlatform(0);
    MapLibrePlatform.createInstance = () => platform;
  });

  tearDown(() {
    MapLibrePlatform.createInstance = previousMapPlatformFactory;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mapChannel, null);
  });

  testWidgets('renders the interactive Riyadh MapLibre map on Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ThurayaApp());
    await tester.pumpAndSettle();

    final searchHint = find.text('ابحث عن مطعم...');
    expect(find.byKey(const ValueKey('home-page')), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(searchHint, findsOneWidget);
    expect(Directionality.of(tester.element(searchHint)), TextDirection.rtl);
    final map = tester.widget<MapLibreMap>(
      find.byKey(const ValueKey('home-map')),
    );
    expect(map.styleString, ThurayaMap.customStyleAsset);
    const riyadh = SupportedMapRegions.riyadh;
    expect(
      map.initialCameraPosition?.target,
      LatLng(riyadh.centerLatitude, riyadh.centerLongitude),
    );
    expect(map.initialCameraPosition?.zoom, riyadh.initialZoom);
    expect(
      map.cameraTargetBounds.bounds,
      LatLngBounds(
        southwest: LatLng(
          riyadh.bounds.southwestLatitude,
          riyadh.bounds.southwestLongitude,
        ),
        northeast: LatLng(
          riyadh.bounds.northeastLatitude,
          riyadh.bounds.northeastLongitude,
        ),
      ),
    );
    expect(map.minMaxZoomPreference.minZoom, riyadh.minimumZoom);
    expect(map.minMaxZoomPreference.maxZoom, riyadh.maximumZoom);
    expect(map.zoomGesturesEnabled, isTrue);
    expect(map.scrollGesturesEnabled, isTrue);
    expect(map.rotateGesturesEnabled, isFalse);
    expect(map.tiltGesturesEnabled, isFalse);
    expect(map.myLocationEnabled, isFalse);
    expect(map.myLocationTrackingMode, MyLocationTrackingMode.none);
    expect(map.attributionButtonPosition, AttributionButtonPosition.bottomLeft);
    expect(map.onStyleLoadedCallback, isNotNull);
    expect(map.onCameraMove, isNotNull);
    expect(map.onCameraIdle, isNotNull);

    expect(
      tester.getRect(find.byKey(const ValueKey('home-search-bar'))),
      const Rect.fromLTWH(20, 20, 350, 66),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('home-current-location'))),
      const Rect.fromLTWH(326, 164, 44, 44),
    );
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('thuraya-bottom-navigation'))),
      const Rect.fromLTWH(0, 732, 390, 80),
    );

    Text navigationLabel(String label) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('thuraya-bottom-navigation')),
        matching: find.text(label),
      ),
    );
    expect(navigationLabel('الرئيسية').style?.color, AppColors.primary);
    expect(navigationLabel('الترند').style?.color, AppColors.textSecondary);
  });

  testWidgets('Home has no overflow on a shorter screen', (tester) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ThurayaApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-search-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-map')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('thuraya-bottom-navigation')),
      findsOneWidget,
    );
  });

  testWidgets('navigates between all implemented main tabs', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ThurayaApp());
    await tester.pumpAndSettle();

    Text navigationLabel(String label) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('thuraya-bottom-navigation')),
        matching: find.text(label),
      ),
    );

    expect(navigationLabel('الرئيسية').style?.color, AppColors.primary);

    await tester.tap(find.byKey(const ValueKey('navigation-wheel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('wheel-page')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('login-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-page')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('navigation-choose-restaurant')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('choose-restaurant-page')),
      findsOneWidget,
    );
    expect(navigationLabel('اختر لي').style?.color, AppColors.primary);

    await tester.tap(find.byKey(const ValueKey('navigation-trending')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trending-page')), findsOneWidget);
    expect(navigationLabel('الترند').style?.color, AppColors.primary);

    await tester.tap(find.byKey(const ValueKey('navigation-account')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-page')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('login-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trending-page')), findsOneWidget);
    expect(navigationLabel('حسابي').style?.color, AppColors.textSecondary);

    await tester.tap(find.byKey(const ValueKey('navigation-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-page')), findsOneWidget);
    expect(navigationLabel('الرئيسية').style?.color, AppColors.primary);
  });

  testWidgets('opens reviews in RTL, scrolls, and returns to details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ThurayaApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const ValueKey('home-page')));
    final restaurant = MockRestaurants.localized(
      AppLocalizations.of(context),
    ).first;
    Navigator.of(
      context,
    ).pushNamed(AppRouteNames.restaurantDetails, arguments: restaurant);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('restaurant-details-reviews')));
    await tester.pumpAndSettle();

    final reviewsTitle = find.text('التقييمات');
    expect(reviewsTitle, findsOneWidget);
    expect(Directionality.of(tester.element(reviewsTitle)), TextDirection.rtl);
    expect(find.text('إيليا للغوص'), findsOneWidget);
    expect(find.text('124 تقييم'), findsOneWidget);
    expect(find.text('عبدالله محمد'), findsOneWidget);

    const longReview =
        'تجربة جميلة جداً، الخدمة ممتازة والطعام كان رائعاً. سأكرر الزيارة بالتأكيد.';
    expect(tester.getSize(find.text(longReview)).height, greaterThan(26));

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('restaurant-reviews-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.scrollUntilVisible(
      find.text('فيصل القحطاني'),
      400,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('restaurant-reviews-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('فيصل القحطاني').hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('restaurant-reviews-back')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('restaurant-details-page')),
      findsOneWidget,
    );
    expect(find.text('124 تقييم'), findsOneWidget);
  });

  testWidgets('shows the Arabic empty reviews state', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ThurayaApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const ValueKey('home-page')));
    final source = MockRestaurants.localized(
      AppLocalizations.of(context),
    ).first;
    final restaurantWithoutReviews = Restaurant(
      id: source.id,
      cardImage: source.cardImage,
      coverImage: source.coverImage,
      name: source.name,
      category: source.category,
      neighborhood: source.neighborhood,
      priceLevel: source.priceLevel,
      rating: 0,
      reviewCount: 0,
      description: source.description,
      galleryImages: source.galleryImages,
      reviews: const [],
      cardStatus: source.cardStatus,
    );

    Navigator.of(context).pushNamed(
      AppRouteNames.restaurantReviews,
      arguments: restaurantWithoutReviews,
    );
    await tester.pumpAndSettle();

    final emptyState = find.text('لا توجد تقييمات حتى الآن');
    expect(emptyState, findsOneWidget);
    expect(Directionality.of(tester.element(emptyState)), TextDirection.rtl);
    expect(
      find.byKey(const ValueKey('restaurant-reviews-empty')),
      findsOneWidget,
    );
  });
}
