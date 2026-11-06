import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thuraya/core/network/api_client.dart';
import 'package:thuraya/core/routing/app_route_names.dart';
import 'package:thuraya/core/widgets/thuraya_result_reveal.dart';
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
      expect(
        find.byKey(const ValueKey('choose-recommendation-thuraya-star')),
        findsOneWidget,
      );
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

    expect(find.byType(ThurayaResultReveal), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('لحظة... ثريا تختار لك'), findsOneWidget);

    pendingRecommendation.complete(_recommendation);
    await request;
    await tester.pump();
  });

  testWidgets(
    'submit starts the shared logo immediately and guards a fast result',
    (tester) async {
      final pending = Completer<ChooseRestaurantResponseDto>();
      final gateway = _ChooseGateway(pending);
      final controller = await _readyToChoose(tester, gateway);
      final button = tester.widget<ButtonStyleButton>(
        find
            .descendant(
              of: find.byKey(const ValueKey('choose-step-action')),
              matching: find.byWidgetPredicate(
                (widget) => widget is ButtonStyleButton,
              ),
            )
            .first,
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 225));
      expect(find.byType(ThurayaResultReveal), findsOneWidget);
      expect(find.byKey(const ValueKey('thuraya-reveal-logo')), findsOneWidget);
      expect(find.byKey(const ValueKey('choose-result-name')), findsNothing);
      expect(gateway.requests, hasLength(1));
      expect(gateway.requests.single.toJson(), {
        'priceLevelIds': [2],
        'categoryIds': [8],
        'neighborhoodIds': [16],
      });
      pending.complete(_recommendation);
      await tester.pump();
      // A queued second press after the fast response must not start another call
      // during the remaining reveal animation.
      button.onPressed!();
      await tester.pump(const Duration(milliseconds: 224));
      expect(_chooseOpacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 351));
      expect(_chooseOpacity(tester), 1);
      expect(gateway.requests, hasLength(1));
      expect(controller.recommendationStatus, RecommendationStatus.success);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'slow request holds the logo with loading, then reveals without replaying',
    (tester) async {
      final pending = Completer<ChooseRestaurantResponseDto>();
      final gateway = _ChooseGateway(pending);
      await _readyToChoose(tester, gateway);
      await tester.tap(find.byKey(const ValueKey('choose-step-action')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const ValueKey('thuraya-reveal-logo')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byKey(const ValueKey('choose-result-name')), findsNothing);
      expect(_chooseOpacity(tester), 0);
      pending.complete(_recommendation);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 175));
      expect(_chooseOpacity(tester), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 175));
      expect(_chooseOpacity(tester), 1);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pumpAndSettle();
    },
  );

  for (final status in [404, 500]) {
    testWidgets(
      'request $status leaves the reveal for existing failure UI and can retry',
      (tester) async {
        final pending = Completer<ChooseRestaurantResponseDto>();
        final gateway = _ChooseGateway(pending);
        await _readyToChoose(tester, gateway);
        await tester.tap(find.byKey(const ValueKey('choose-step-action')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        pending.completeError(
          ApiException('No recommendation', statusCode: status),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ThurayaResultReveal), findsNothing);
        expect(
          find.byKey(
            ValueKey(
              status == 404 ? 'choose-no-match' : 'choose-request-error',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('choose-result-name')), findsNothing);
        gateway.pendingRecommendation = null;
        final l10n = AppLocalizations.of(
          tester.element(
            find.byKey(
              ValueKey(
                status == 404 ? 'choose-no-match' : 'choose-request-error',
              ),
            ),
          ),
        );
        await tester.tap(
          find.text(status == 404 ? l10n.chooseAnother : l10n.retry),
        );
        await tester.pumpAndSettle();
        expect(gateway.requests, hasLength(2));
        expect(
          find.byKey(const ValueKey('choose-result-name')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'choose again replays once and existing details action retains the selected ID',
    (tester) async {
      final gateway = _ChooseGateway();
      RouteSettings? opened;
      await _readyToChoose(
        tester,
        gateway,
        onRoute: (settings) => opened = settings,
      );
      await tester.tap(find.byKey(const ValueKey('choose-step-action')));
      await tester.pumpAndSettle();
      final firstRevealKey = tester
          .widget<ThurayaResultReveal>(find.byType(ThurayaResultReveal))
          .key;
      final again = find.byKey(const ValueKey('choose-another'));
      await tester.ensureVisible(again);
      await tester.pumpAndSettle();
      await tester.tap(again);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 225));
      expect(
        tester
            .widget<ThurayaResultReveal>(find.byType(ThurayaResultReveal))
            .key,
        isNot(firstRevealKey),
      );
      expect(find.byKey(const ValueKey('thuraya-reveal-logo')), findsOneWidget);
      expect(gateway.requests, hasLength(2));
      await tester.pumpAndSettle();
      final details = find.byKey(const ValueKey('choose-view-restaurant'));
      await tester.ensureVisible(details);
      await tester.pumpAndSettle();
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(opened?.name, AppRouteNames.restaurantDetailsFor(1));
      expect(opened?.arguments, 1);
    },
  );

  testWidgets(
    'back cancels a pending reveal and late data cannot replace preferences',
    (tester) async {
      final pending = Completer<ChooseRestaurantResponseDto>();
      final gateway = _ChooseGateway(pending);
      final controller = await _readyToChoose(tester, gateway);
      await tester.tap(find.byKey(const ValueKey('choose-step-action')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('choose-back')));
      await tester.pumpAndSettle();
      pending.complete(_recommendation);
      await tester.pumpAndSettle();
      expect(controller.recommendationStatus, RecommendationStatus.idle);
      expect(find.byType(ThurayaResultReveal), findsNothing);
      expect(
        find.byKey(const ValueKey('choose-neighborhood-step')),
        findsOneWidget,
      );
      expect(controller.selectedCategoryIds, {8});
    },
  );

  for (final locale in ['ar', 'en']) {
    testWidgets(
      'reduced motion still waits for selection and uses $locale result content',
      (tester) async {
        final pending = Completer<ChooseRestaurantResponseDto>();
        await _readyToChoose(
          tester,
          _ChooseGateway(pending),
          locale: locale,
          disableAnimations: true,
        );
        await tester.tap(find.byKey(const ValueKey('choose-step-action')));
        await tester.pump();
        expect(find.byKey(const ValueKey('choose-result-name')), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        pending.complete(_recommendation);
        await tester.pumpAndSettle();
        expect(_chooseOpacity(tester), 1);
        final name = find.byKey(const ValueKey('choose-result-name'));
        expect(
          tester.widget<Text>(name).data,
          locale == 'ar' ? 'ساكورا الرياض' : 'Riyadh Sakura',
        );
        expect(
          Directionality.of(tester.element(name)),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
      },
    );
  }
}

double _chooseOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.byKey(const ValueKey('thuraya-result-entrance')),
    )
    .opacity
    .value;

Future<ChooseRestaurantController> _readyToChoose(
  WidgetTester tester,
  _ChooseGateway gateway, {
  String locale = 'ar',
  bool disableAnimations = false,
  ValueChanged<RouteSettings>? onRoute,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = ChooseRestaurantController(
    lookupGateway: _LookupGateway(),
    chooseGateway: gateway,
    detailsLoader: (_) => Future.error(Exception('No details')),
  );
  addTearDown(controller.dispose);
  await controller.initialize();
  controller.togglePriceLevel(2);
  controller.toggleCategory(8);
  controller.toggleNeighborhood(16);
  controller.nextStep();
  controller.nextStep();
  await tester.pumpWidget(
    _TestApp(
      controller: controller,
      locale: Locale(locale),
      disableAnimations: disableAnimations,
      onRoute: onRoute,
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.controller,
    this.locale = const Locale('ar'),
    this.disableAnimations = false,
    this.onRoute,
  });
  final ChooseRestaurantController controller;
  final Locale locale;
  final bool disableAnimations;
  final ValueChanged<RouteSettings>? onRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      onGenerateRoute: (settings) {
        onRoute?.call(settings);
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Restaurant details')),
        );
      },
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
  _ChooseGateway([this.pendingRecommendation]);

  Completer<ChooseRestaurantResponseDto>? pendingRecommendation;
  final requests = <ChooseRestaurantRequest>[];

  @override
  Future<ChooseRestaurantResponseDto> choose(
    ChooseRestaurantRequest request,
  ) async {
    requests.add(request);
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
