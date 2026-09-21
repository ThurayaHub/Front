import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/widgets/thuraya_loading_indicator.dart';
import 'package:thuraya/features/choose_restaurant/models/choose_restaurant_dto.dart';
import 'package:thuraya/features/choose_restaurant/models/restaurant_lookup.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_controller.dart';
import 'package:thuraya/features/choose_restaurant/presentation/choose_restaurant_page.dart';
import 'package:thuraya/features/choose_restaurant/services/choose_restaurant_service.dart';
import 'package:thuraya/features/choose_restaurant/services/restaurant_lookup_service.dart';
import 'package:thuraya/features/restaurant_details/models/restaurant_details_dto.dart';
import 'package:thuraya/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('renders an RTL Arabic guided flow and keeps multi-selections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = _ChooseGateway();
    final controller = ChooseRestaurantController(
      lookupGateway: _LookupGateway(),
      chooseGateway: gateway,
      detailsLoader: (_) => Future.error(Exception()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();

    final heading = find.text('وش ميزانيتك؟');
    expect(Directionality.of(tester.element(heading)), TextDirection.rtl);
    expect(find.text('اقتصادي'), findsOneWidget);
    expect(find.text('متوسط'), findsOneWidget);
    expect(find.text('Cheap'), findsNothing);
    expect(find.text('1 من 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('choose-price-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('choose-price-2')));
    await tester.pump();
    expect(controller.selectedPriceLevelIds, {1, 2});
    await tester.tap(find.byKey(const ValueKey('choose-step-action')));
    await tester.pumpAndSettle();

    expect(find.text('وش تشتهي اليوم؟'), findsOneWidget);
    expect(find.byKey(const ValueKey('choose-category-all')), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('آسيوي'), findsOneWidget);
    expect(find.text('ياباني'), findsOneWidget);
    expect(find.text('Asian'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('choose-category-8')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('choose-step-action')));
    await tester.pumpAndSettle();

    expect(find.text('وين ودك تاكل؟'), findsOneWidget);
    expect(find.byKey(const ValueKey('choose-neighborhood-search')), findsOne);
    await tester.enterText(
      find.byKey(const ValueKey('choose-neighborhood-search')),
      'ملقا',
    );
    await tester.pump();
    expect(find.text('الملقا'), findsOneWidget);
    expect(find.text('العليا'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('choose-neighborhood-16')));
    await tester.pump();

    expect(controller.selectedPriceLevelIds, {1, 2});
    expect(controller.selectedCategoryIds, {8});
    expect(controller.selectedNeighborhoodIds, {16});
  });

  testWidgets('all cuisines advances without a category filter', (
    tester,
  ) async {
    final controller = ChooseRestaurantController(
      lookupGateway: _LookupGateway(),
      chooseGateway: _ChooseGateway(),
      detailsLoader: (_) => Future.error(Exception()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('choose-price-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('choose-step-action')));
    await tester.pumpAndSettle();

    expect(controller.canContinue, isFalse);
    await tester.tap(find.byKey(const ValueKey('choose-category-all')));
    await tester.pump();

    expect(controller.allCategoriesSelected, isTrue);
    expect(controller.selectedCategoryIds, isEmpty);
    expect(controller.canContinue, isTrue);

    await tester.tap(find.byKey(const ValueKey('choose-step-action')));
    await tester.pumpAndSettle();
    expect(find.text('وين ودك تاكل؟'), findsOneWidget);
  });

  testWidgets(
    'renders real recommendation data and never fakes Thuraya rating',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = _ChooseGateway();
      final controller = ChooseRestaurantController(
        lookupGateway: _LookupGateway(),
        chooseGateway: gateway,
        detailsLoader: (_) => Future.error(Exception()),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      controller.togglePriceLevel(2);
      controller.toggleCategory(8);

      await tester.pumpWidget(_TestApp(controller: controller));
      await tester.pumpAndSettle();
      await controller.requestRecommendation();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('choose-recommendation-result')),
        findsOne,
      );
      expect(find.text('ساكورا الرياض'), findsOneWidget);
      expect(find.text('مطعم ياباني عصري.'), findsOneWidget);
      expect(find.text('ياباني • متوسط'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(8)'), findsOneWidget);
      expect(find.text('0.0'), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    },
  );

  testWidgets('uses branded loading while Thuraya chooses a restaurant', (
    tester,
  ) async {
    final pendingRecommendation = Completer<ChooseRestaurantResponseDto>();
    final controller = ChooseRestaurantController(
      lookupGateway: _LookupGateway(),
      chooseGateway: _ChooseGateway(pendingRecommendation),
      detailsLoader: (_) => Future.error(Exception()),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    controller.togglePriceLevel(2);
    controller.toggleCategory(8);

    await tester.pumpWidget(_TestApp(controller: controller));
    await tester.pumpAndSettle();
    final request = controller.requestRecommendation();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('choose-recommendation-loading')),
      findsOneWidget,
    );
    expect(find.byType(ThurayaLoadingIndicator), findsOneWidget);
    expect(find.text('لحظة... ثريا تختار لك'), findsOneWidget);

    pendingRecommendation.complete(_recommendation);
    await request;
    await tester.pump();
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller});
  final ChooseRestaurantController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChooseRestaurantPage(controller: controller),
    );
  }
}

class _LookupGateway implements RestaurantLookupGateway {
  @override
  Future<List<RestaurantLookupItemDto>> getPriceLevels() async => const [
    RestaurantLookupItemDto(id: 1, name: 'Cheap', description: null),
    RestaurantLookupItemDto(id: 2, name: 'Medium', description: null),
  ];

  @override
  Future<List<RestaurantLookupItemDto>> getCategories() async => const [
    RestaurantLookupItemDto(id: 2, name: 'Asian', description: null),
    RestaurantLookupItemDto(id: 8, name: 'Japanese', description: null),
  ];

  @override
  Future<List<NeighborhoodLookupDto>> getNeighborhoods() async => const [
    NeighborhoodLookupDto(
      id: 15,
      nameAr: 'العليا',
      nameEn: 'Al Olaya',
      cityAr: 'الرياض',
      cityEn: 'Riyadh',
      countryCode: 'SA',
    ),
    NeighborhoodLookupDto(
      id: 16,
      nameAr: 'الملقا',
      nameEn: 'Al Malqa',
      cityAr: 'الرياض',
      cityEn: 'Riyadh',
      countryCode: 'SA',
    ),
  ];
}

class _ChooseGateway implements ChooseRestaurantGateway {
  const _ChooseGateway([this.pendingRecommendation]);

  final Completer<ChooseRestaurantResponseDto>? pendingRecommendation;

  @override
  Future<ChooseRestaurantResponseDto> choose(
    ChooseRestaurantRequest request,
  ) async {
    final pending = pendingRecommendation;
    if (pending != null) return pending.future;
    return _recommendation;
  }
}

const _recommendation = ChooseRestaurantResponseDto(
  id: 1,
  name: 'Riyadh Sakura',
  nameArabic: 'ساكورا الرياض',
  description: 'A modern Japanese restaurant.',
  descriptionArabic: 'مطعم ياباني عصري.',
  address: 'Riyadh',
  latitude: 24.7,
  longitude: 46.6,
  googleMapsUrl: 'https://maps.example/1',
  priceLevelId: 2,
  priceLevelName: 'Medium',
  neighborhoodId: null,
  neighborhoodNameAr: null,
  neighborhoodNameEn: null,
  userRatingAverage: 4.5,
  reviewCount: 8,
  mainPhotoUrl: null,
  hasThurayaStar: true,
  categories: [RestaurantCategoryDto(id: 8, name: 'Japanese')],
);
